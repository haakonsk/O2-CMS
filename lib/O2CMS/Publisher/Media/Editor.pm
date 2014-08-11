package O2CMS::Publisher::Media::Editor;

# Responsible for rendering a page suitable for editing

use strict;

use O2 qw($context $config);

#------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  die "Missing page"   unless $init{page};
  die "Missing parser" unless $init{parser};
  
  require O2::Javascript::Data;
  return bless {
    page    => $init{page},
    parser  => $init{parser},
    jsData  => O2::Javascript::Data->new(),
  }, $pkg;
}
#------------------------------------------------------------------
# returns html for a slot including header control panel
sub renderSlot {
  my ($obj, %params) = @_;

  my $class  =  $params{class}  ?  "$params{class} o2Slot"  :  'o2Slot';

  my $html = "<div component=\"Slot\" class=\"$class\" id=\"slot_$params{slotId}\" onmouseover=\"slotFocus('$params{slotId}')\" onmouseout=\"slotUnfocus('$params{slotId}')\">";
  $html   .= "<div class=\"o2SlotHeader\" id=\"slotHeader_$params{slotId}\" onmouseover=\"slotFocus('$params{slotId}')\"></div>";
  $html   .= "<div id=\"slotContent_$params{slotId}\">";
  $html   .= $obj->renderSlotContent(%params, slotId=>$params{slotId}, extraHtml => '<o2 use Html />');
  my @accepts = split(/,\s*/, $params{accepts});
  $html   .= "</div></div><script>getComponentById('slot_$params{slotId}').setAccepts(".$obj->{jsData}->dump(\@accepts).")</script>";
  return $html;
}
#------------------------------------------------------------------
sub _getGridsOrIncludes {
  my ($obj, $Type, %params) = @_;
  my $mgr = $context->getSingleton("O2CMS::Mgr::Template::${Type}Manager");
  my @templates = $mgr->queryGridsOrIncludes(
    $Type,
    templateMatch => $params{templateMatch},
    accepts       => $params{accepts},
  );
  @templates = grep { -e $_->getFullPath()                               } @templates;
  @templates = map  {  { id => $_->getId(), name => $_->getMetaName() }  } @templates;
  return @templates;
}
#------------------------------------------------------------------
# returns content html for a slot (without header control panel)
sub renderSlotContent {
  my ($obj, %params) = @_;

  my $slotList = $obj->{page}->getSlotList();
  my $slot = $slotList->getSlotById( $params{slotId} );

  my @grids    = $obj->_getGridsOrIncludes('Grid');
  my @includes = $obj->_getGridsOrIncludes('Include');

  # return tag-content unless we have a proper object
  my $emptyText = $obj->{jsData}->dump( $params{content} );
  my $noContent = !$slot || !$slot->getContentId();
  my $object = eval {
    $context->getObjectById( $slot->getContentId() );
  };
  $noContent = 1 unless $object;
  if ($noContent) {
    my $grids    = $obj->{jsData}->dump(\@grids);
    my $includes = $obj->{jsData}->dump(\@includes);
    return "<script type=\"text/javascript\">getComponentById('slot_$params{slotId}').setContentInfo({localSlot:{}, externalSlot:{}, templateMatch: '$params{templateMatch}', defaultTemplate: '$params{defaultTemplate}', emptyText:$emptyText, nextSlot: '$params{next}', grids: $grids, includes: $includes});</script>";
  }

  # parse template with object and slot
  my $fileMgr = $context->getSingleton('O2::File');
  my $tmpl;
  my @templateOptions;
  my $templateId = $slot->getTemplateId();
  my $template;
  if ( $object->isa('O2CMS::Obj::Template') ) {
    $tmpl = $object->getTemplateRef();
  }
  else {
    my $user = $context->getUser();
    $object->setCurrentLocale( $user->getAttribute('frontendLocaleCode') );
    # This slot contains an object. Figure out what template to use.
    # Choose a different template if template does not match content object. This will happen when you drop a 
    if ($templateId) {
      $template = $context->getObjectById($templateId);
      $templateId = undef unless $template && $template->isUsableForClass( $object->getMetaClassName() );
    }
    
    my @templates = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager')->queryTemplates(
      class         => $object->getMetaClassName(),
      templateMatch => $params{templateMatch},
    );
    
    foreach my $template (@templates) {
      $templateId = $template->getId() if !defined $templateId && $template->getFileName() eq 'default.html';
      $templateId = $template->getId() if !defined $templateId && ($params{defaultTemplate} eq $template->getPrettyName() || $params{defaultTemplate} eq $template->getFileName());
      push @templateOptions, {
        name => $template->getPrettyName(),
        id   => $template->getId(),
      };
    }
    
    @templateOptions = sort { $a->{name} cmp $b->{name} } @templateOptions;
    # default to first template if 'default.html' wasn't found or no defaultTemplate attribute was specified
    $templateId = $templateOptions[0]->{id} if !defined $templateId && @templateOptions;

    $slot->setTemplateId($templateId);
    if ($templateId > 0) {
      my $template = $context->getObjectById($templateId);
      $tmpl = $template->getTemplateRef();
    }
    else {
      $tmpl = $fileMgr->getFileRef("o2://var/templates/Page/Editor/templateUndefined.html");
      $obj->{parser}->setVar( 'templateMatch', $params{templateMatch} );
    }
  }
  
  my $parser = $obj->{parser};
  $template = $context->getObjectById($templateId) if $templateId;
  $parser->pushProperty( 'currentTemplate', $template->getPath() ) if $template;
  
  ${$tmpl} = '<o2 use O2CMS::Page pageRenderer="$pageRenderer" />' . ${$tmpl};
  ${$tmpl} = $params{extraHtml} . ${$tmpl} if $params{extraHtml};
  
  $obj->{currentObject} = $object;
  $obj->{currentSlot}   = $slot;
  $slot->setOverrideByName( '_isListSlot',     0                        ); # reset slot status. renderListSlot() will change this for lists
  $slot->setOverrideByName( 'defaultTemplate', $params{defaultTemplate} );
  my $originalObject = $parser->getVar('$object');
  $parser->setVar( '$object', $object );
  $parser->setVar( '$slot',   $slot   );
  
  my $parseMethod = $obj->{parser}->getProperty('reloadingSingleSlot') ? 'parse' : '_parse';
  my $html = ${ $parser->$parseMethod($tmpl) };
  
  $parser->setVar('$object', $originalObject);
  $obj->{currentObject} = undef;
  $obj->{currentSlot}   = undef;
  
  $parser->popProperty('currentTemplate') if $template;
  
  my $localSlot    = $slotList->getLocalSlotById(    $params{slotId} );
  my $externalSlot = $slotList->getExternalSlotById( $params{slotId} );

  # Set defaultTemplateId as an override value
  if (!$slot->getOverrideByName('defaultTemplateId')) {
    my $slotId = $slot->getSlotId();
    my $valueIsSet = 0;
  WHILE:
    while ($slotId =~ m{ [.] }xms) {
      $slotId =~ s{ [.] [^.]+ \z }{}xms;
      my $_slot = $slotList->getSlotById($slotId);
      die "Didn't find slot with id $slotId " unless $_slot;
      if ($_slot->getOverrideByName('defaultTemplateId')) {
        $slot->setOverrideByName('defaultTemplateId', $_slot->getOverrideByName('defaultTemplateId'));
        $valueIsSet = 1;
        last;
      }
      if (!$valueIsSet  &&  ( my $defaultTemplate = $params{defaultTemplate} || $_slot->getOverrideByName('defaultTemplate') )) {
        my $prettyName = ucfirst $defaultTemplate;
        $prettyName    =~ s{ [.]html? \z }{}xms;
        my $objectMgr = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager');
        my @templates = $objectMgr->queryTemplates( class => $object->getMetaClassName() );
        foreach my $template (@templates) {
          if ($template->getPrettyName() eq $prettyName) {
            $slot->setOverrideByName( 'defaultTemplateId', $template->{id} );
            last WHILE;
          }
        }
      }
    }
  }

  # disable slots where content comes from external slot
  my $isDisabled
    =      $config->get('publisher.allowSlotOverride') ne 'yes'
      &&   $externalSlot && $externalSlot->getContentId() > 0
      && (!$localSlot || $localSlot->getContentId() == 0)
      &&  !$externalSlot->getOverrideByName('_isInherited')
    ;

  # inform the JS Slot component about the content
  my $contentInfo = $obj->{jsData}->dump({
    name            => $object->getMetaName(),
    className       => $object->getMetaClassName(),
    templateOptions => \@templateOptions,
    grids           => \@grids,
    localSlot       => $localSlot    ? { $localSlot->toHash()    } : {},
    externalSlot    => $externalSlot ? { $externalSlot->toHash() } : {},
    templateMatch   => $params{templateMatch},
    defaultTemplate => $params{defaultTemplate},
    isDisabled      => $isDisabled,
    emptyText       => $emptyText,
    nextSlot        => $params{next},
    isPublishable   => $object->isPublishable(),
  });
  $html .= "<script type=\"text/javascript\">getComponentById('slot_$params{slotId}').setContentInfo($contentInfo);</script>";
  return $html;
}
#------------------------------------------------------------------
sub renderPage {
  my ($obj) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  my $page = $obj->{page};
  my $templatePath = $fileMgr->resolvePath('o2://var/templates/Page/Editor/editorTop.html');
  my $tmpl = $fileMgr->getFileRef($templatePath);
  
  my $contentTmpl = $page->getTemplateRef();
  if ($contentTmpl) {
    ${$tmpl} .= ${$contentTmpl};
  }
  else {
    ${$tmpl} = 'Missing page template in renderPage()';
  }
  ${$tmpl} .= "<o2 footer/>";

  $obj->{parser}->pushProperty('currentTemplate', "$templatePath or " . ($page->can('getTemplate') ? $page->getTemplate()->getFullPath() : $page->getPath()));
  $obj->{parser}->parse($tmpl);
  $obj->{parser}->popProperty('currentTemplate');

  my $slotList = $page->getSlotList();
  ${$tmpl} = ${$tmpl} . '<script type="text/javascript">slotList.setSlots('        . $obj->_slotsToJsStruct( $slotList->getLocalSlots()    ) . ");</script>\n";
  ${$tmpl} = ${$tmpl} . '<script type="text/javascript">slotList.setDefaultSlots(' . $obj->_slotsToJsStruct( $slotList->getExternalSlots() ) . ");</script>\n";

  return $tmpl;
}
#------------------------------------------------------------------
sub _slotsToJsStruct {
  my ($obj, @slots) = @_;
  my %slots;
  foreach my $slot (@slots) {
    my %override = $slot->getOverride();
    $slots{ $slot->getSlotId() } = {
      contentId  => $slot->getContentId(),
      templateId => $slot->getTemplateId(),
      override   => \%override,
    };
  }
  return $obj->{jsData}->dump(\%slots);
}
#------------------------------------------------------------------
sub renderObjectImage {
  my ($obj, %params) = @_;
  return "Missing width or height for $params{field} image" unless $params{width}>0 || $params{height}>0;
  $params{width}  = 2000 unless $params{width};
  $params{height} = 2000 unless $params{height};

  my $fieldId = "imageField_$params{slotId}.$params{field}";
  my $html = qq{<div id="$fieldId" component="ImageField"></div>};

  my $imageId = eval {
    $obj->_getField( field => $params{field} );
  };
  return "Image $params{field} error: $@" if $@;

  if ($imageId > 0) {
    my $image = $context->getObjectById($imageId);
    return "Field '$params{field}' contained '$imageId'. It does not refer to a O2::Obj::Image object" unless $image && $image->isa('O2::Obj::Image');
    
    require O2::Image::Image;
    my $scaledPath = $image->getScaledPath( $params{width}, $params{height} );
    my $scaledImg = O2::Image::Image->newFromFile($scaledPath);
    if (lc($params{editable}) eq 'yes') {
      my $contentInfo = $obj->{jsData}->dump({
        imageId   => $image->getId(),
        name      => $image->getMetaName().$image->getScaledUrl($params{width}, $params{height}),
        imageUrl  => $image->getScaledUrl($params{width}, $params{height}),
        width     => $params{width},
        height    => $params{height},
      });
      $html .= qq{<script type="text/javascript">getComponentById('$fieldId').setImageInfo($contentInfo)</script>};
    }
    else {
      $html .= '<img src="' . $image->getScaledUrl($params{width}, $params{height}) . '">';
    }
  }
  return $html;
}
#------------------------------------------------------------------
sub renderObjectString {
  my ($obj, %params) = @_;
  my $value = eval {
    $obj->_getField(
      field        => $params{field},
      virtual      => $params{virtual},
      defaultValue => $params{content},
    );
  };
  return 'Error in ' . $obj->{parser}->getProperty('currentTemplate') . ": $@" if $@;
  return $value if lc $params{editable} ne 'yes';

  my $slotId = $params{slotId} || $params{field};
  my $html = qq{<a href="javascript: toggleEditSlotString('$slotId')"><img src="/images/system/edit_16.gif"></a>};
  $html   .= qq{<span id="slotStringValue_$slotId">$value</span>};
  $html   .= qq{<textarea style="display:none; border:none;" id="slotString_$slotId" onchange="slotList.setOverride('$slotId','$params{field}', this.value)">$value</textarea>};
  return $html;
}
#------------------------------------------------------------------
sub _getField {
  my ($obj, %params) = @_;
  my $slot = $obj->{currentSlot};
  if (!$slot) {
    my $slotList = $obj->{page}->getSlotList();
    $slot = $slotList->getSlotById( $params{field} );
    $obj->{currentSlot} = $slot;
  }
  my $value = $slot->getOverrideByName($params{field});
  # use override only if it contains anything (so user may disable it by removing content)
  return $value if length $value;

  # method call is disabled through "virtual" attribute.
  if (lc ($params{virtual}) eq 'yes') {
    $obj->{parser}->_parse( \$params{defaultValue} );
    return $params{defaultValue};
  }

  # no override. try invoking method in dataobject
  require O2::Util::AccessorMapper;
  my $accessorMapper = O2::Util::AccessorMapper->new();
  my %values = $accessorMapper->getAccessors( $obj->{currentObject}, $params{field} => 'scalar' ); # this might die if $field does not refer to a method
  return $values{ $params{field} };
}
#------------------------------------------------------------------
sub _getGridMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2CMS::Mgr::Template::GridManager');
}
#------------------------------------------------------------------
1;
