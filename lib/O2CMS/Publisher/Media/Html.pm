package O2CMS::Publisher::Media::Html;

# Responsible for rendering a page as html

use strict;

use O2 qw($context $cgi $config);

#------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  die "Missing page"    unless $init{page};
  die "Missing parser"  unless $init{parser};
  
  require O2::Javascript::Data;
  my $obj = bless {
    page      => $init{page},
    parser    => $init{parser},
    jsData    => O2::Javascript::Data->new(),
  }, $pkg;
  return $obj;
}
#------------------------------------------------------------------
sub getCachedUrl {
  my ($obj) = @_;
  return $obj->{cachedUrl} if $obj->{cachedUrl};
  return $obj->{cachedUrl} = $obj->{page}->getUrl();
}
#------------------------------------------------------------------
# returns html for a slot including header control panel
sub renderSlot {
  my ($obj, %params) = @_;
  return $obj->renderSlotContent(%params, extraHtml => '<o2 use Html />');
}
#------------------------------------------------------------------
# returns content html for a slot (without header control panel)
sub renderSlotContent {
  my ($obj, %params) = @_;

  $obj->_debug("renderSlotContent($params{slotId})");
  my $slot = $obj->{page}->getSlotById( $params{slotId} );
  return $params{content} if !$slot || !$slot->getContentId(); # default to content between <o2 slot> and </o2>

  my $object = $context->getObjectById( $slot->getContentId() );
  $object    = $object->getUnserializedObject() if $object && $object->isa('O2CMS::Obj::Draft');
  return "<!-- slot '$params{slotId}': content object (" . $slot->getContentId()  . ') deleted -->'     unless  $object;
  return "<!-- slot '$params{slotId}': content object (" . $object->getMetaName() . ') not publishable -->' if !$object->isPublishable( $obj->getCachedUrl() ) && !$cgi->getParam('preview');

  # handle multilinguality
  if ( $object->can('isMultilingual') && $object->isMultilingual() ) {
    my %usedLocales = map { $_=>1 } $object->getUsedLocales();
    
    # current locale not available?
    my $currentLocale = $object->getCurrentLocale();
    if ( !$usedLocales{$currentLocale} ) {
      my $fallbackLocale = $config->get('o2.defaultLocale');
      # fall back to fallback locale, or empty slot if not available
      if ( $usedLocales{$fallbackLocale} ) {
        $object->setCurrentLocale($fallbackLocale);
      }
      else {
        return '<!-- '.$object->getMetaName().'('.$object->getId().") not available for locale $currentLocale -->";
      }
    }
  }

  # parse template with object and slot
  my $tmpl;
  my @templateOptions;
  my $templateId = $slot->getTemplateId();
  my $parser = $obj->{parser};
  if ($object->isa('O2CMS::Obj::Template')) {
    $tmpl = $object->getTemplateRef();
  }
  else {
    if ($templateId > 0) {
      my $template = $context->getObjectById($templateId);
      return '' unless $template;
      $obj->_debug("Template for $params{slotId}: " . $template->getPath());
      $parser->pushProperty( 'currentTemplate', $template->getFullPath() );
      $tmpl = $template->getTemplateRef();
    }
    else {
      ${$tmpl} = "Slot templateId undefined for slot '$params{slotId}'";
    }
  }
  ${$tmpl}  = '<o2 use O2CMS::Page pageRenderer="$pageRenderer"/>' . ${$tmpl};
  ${$tmpl} .= $params{extraHtml} if $params{extraHtml};
  $obj->{currentObject} = $object;
  $obj->{currentSlot}   = $slot;
  my $originalObject = $parser->getVar('$object');
  $parser->setVar('$object', $object);
  $parser->setVar('$slot',   $slot);
  my $html = ${ $parser->_parse($tmpl) };
  $parser->setVar('$object', $originalObject);
  $parser->popProperty('currentTemplate');
  $obj->{currentObject} = undef;
  $obj->{currentSlot}   = undef;
  return $html;
}
#------------------------------------------------------------------
sub renderPage {
  my ($obj) = @_;
  my $page = $obj->{page};
  my $path = $page->isa('O2CMS::Obj::Page') ? $page->getTemplate()->getFullPath() : $page->getFullPath();
  
  $obj->{parser}->pushProperty('currentTemplate', $path);
  my $mainTmpl = $obj->{page}->getTemplateRef();
  ${$mainTmpl} = 'Missing main template' unless $mainTmpl;
  ${$mainTmpl} = '<o2 use O2CMS::Page pageRenderer="$pageRenderer"/>' . ${$mainTmpl};
  $obj->{parser}->parse($mainTmpl);
  $obj->{parser}->popProperty('currentTemplate');
  $obj->_includeGoogleAnalyticsCode($mainTmpl);
  return $mainTmpl;
}
#------------------------------------------------------------------
sub _includeGoogleAnalyticsCode {
  my ($obj, $tmplRef) = @_;
  my $analyticsMgr = $context->getSingleton('O2CMS::Mgr::Statistics::GoogleAnalyticsManager');
  my $account;
  eval {
    $account = $analyticsMgr->getAccountByCurrentSite();
  };
  return if $@ || !$account;
  my $javascript = $account->getJavascript();
  ${$tmplRef} =~ s{ </body> }{ $javascript</body> }xms;
}
#------------------------------------------------------------------
sub renderObjectImage {
  my ($obj, %params) = @_;
  return "Missing width or height for $params{property} image" unless $params{width}>0 || $params{height}>0;
  $params{width}  = 2000 unless $params{width};
  $params{height} = 2000 unless $params{height};
  
  my $imageId = eval {
    $obj->_getField( field => $params{field} );
  };
  return "Image $params{field} error: $@" if $@;
  
  if ($imageId > 0) {
    my $image = $context->getObjectById($imageId);
    return "Property '$params{property}' contained '$imageId'. Id does not refer to a O2::Obj::Image object" unless $image && $image->isa('O2::Obj::Image');
    my $scaledUrl = $image->getScaledUrl( $params{width}, $params{height} );
    return "<img src=\"$scaledUrl\">";
  }
  return '[Empty image]';
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
  return "Error: $@" if $@;
  return $value;
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
  my $value = $slot->getOverrideByName( $params{field} );
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
sub _debug {
  my ($obj, $msg) = @_;
#  print "<font color=#0000FF>$msg</font><br>";
}
#------------------------------------------------------------------
1;
