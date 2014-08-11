package O2CMS::Backend::Gui::Page::Editor;

# Gui module for editing O2CMS::Obj::Template::Grid and O2CMS::Obj::Template::Page objects.

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $config);

#------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  my $page = $obj->getObjectByParam('objectId');
  $obj->_edit($page, 'Editor');
}
#------------------------------------------------------------------
sub newPage {
  my ($obj) = @_;
  my $parentId  = $obj->getParam('parentId');
  my $name      = $obj->getParam('name');
  my $className = $obj->getParam('className');
  
  my $parent = $context->getObjectById($parentId) or die 'Parent not found';
  my ($templateId) = $parent->getPropertyValue( 'pageTemplateId.' . $obj->getParam('className') );
  
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my $page = $universalMgr->newObjectByClassName( $obj->getParam('className') );
  
  # Check if category already has a frontpage
  if ( $page->isa('O2CMS::Obj::Frontpage') ) {
    my $frontpage = $context->getSingleton('O2CMS::Mgr::FrontpageManager')->getFrontpageByCategoryId($parentId);
    die $obj->getLang()->getString( 'o2.pageEditor.errorSectionHasFrontpage', id => $frontpage->getId() ) if $frontpage;
  }
  
  $page->setTemplateId(   $templateId );
  $page->setMetaParentId( $parentId   );
  $page->setMetaName(     $name       );
  
  $obj->_edit($page,'Editor');
}
#------------------------------------------------------------------
# reload editor page. Receive serialized object, unserialize and display page again.
sub reloadPage {
  my ($obj) = @_;
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  my $pageData = $jsData->undumpXml( $obj->getParam('pageData') );
  
  # restore object
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my $page = $pageData->{id}  ?  $context->getObjectById( $pageData->{id} )  :  $universalMgr->newObjectByClassName( $pageData->{className} );
  die 'Page not found' unless $page;
  
  $page->setTemplateId(   $pageData->{templateId} );
  $page->setMetaParentId( $pageData->{parentId}   );
  $page->setMetaName(     $pageData->{name}       );
  $page->getSlotList()->setLocalSlotsHash( %{ $pageData->{slots} } );
  $obj->_edit( $page, $obj->getParam('media') );
}
#------------------------------------------------------------------
sub _edit {
  my ($obj, $page, $media) = @_;
  my $pageTemplateMgr = $context->getSingleton('O2CMS::Mgr::Template::PageManager');
  my @pageTemplates = $pageTemplateMgr->getPageTemplates() or die 'No page templates installed';
  
  $page->setTemplateId( $pageTemplates[0]->getId() ) if $page->isa('O2CMS::Obj::Page') && !$page->getTemplateId();
  
  # Find out if $frontpageIsCachable should be 'yes', 'no' or 'inherit':
  my $property = $context->getSingleton('O2::Mgr::PropertyManager')->getProperty( $page->getId(), 'isPageCachable' );
  my $frontpageIsCachable = 'inherit';
  if ($property && !$property->isInherited()) {
    $frontpageIsCachable = $property->getValue() eq 'yes' || $property->getValue() eq '1'  ?  'yes'  :  'no';
  }
  
  require O2CMS::Publisher::PageRenderer;
  my $pageRenderer = O2CMS::Publisher::PageRenderer->new(
    page  => $page,
    media => $media,
  );
  $pageRenderer->setTemplateVariable( 'pageTemplates',       \@pageTemplates                );
  $pageRenderer->setTemplateVariable( 'page',                $page                          );
  $pageRenderer->setTemplateVariable( 'templateType',        $obj->getParam('templateType') );
  $pageRenderer->setTemplateVariable( 'frontpageIsCachable', $frontpageIsCachable           );
  
  # "Hack" for multilingual titles
  
  my %title;
  foreach my $locale ($page->getUsedLocales()) {
    $page->setCurrentLocale($locale);
    $title{$locale} = $page->getTitle();
  }
  $pageRenderer->setTemplateVariable('titles', \%title);

  my $user = $context->getUser();
  if ($obj->getParam('localeCode')) {
    $page->setCurrentLocale( $obj->getParam('localeCode') );
  }
  elsif ($user->getAttribute('frontendLocaleCode')) {
    $page->setCurrentLocale( $user->getAttribute('frontendLocaleCode') );
  }
  $context->setLocaleCode( $page->getCurrentLocale() );
  print $pageRenderer->renderPage();
}
#------------------------------------------------------------------
sub openRevision {
  my ($obj, $page, $revisionId) = @_;
  $obj->_edit($page, 'Editor');
}
#------------------------------------------------------------------
sub unpublishObjectForSlot {
  my ($obj) = @_;
  my $page = $obj->getObjectByParam('pageId');
  $page->unpublishFromSlot( $obj->getParam('slotId') );
  $page->save(); # In order to regenerate cache
  return 1;
}
#------------------------------------------------------------------
# print out content of a O2CMS::Obj::Template::Grid object
sub dumpObject {
  my ($obj) = @_;
  my $object = $obj->getObjectByParam('objectId');
  
  print "ClassName: " . $object->getMetaClassName() . "<br>";
  if ( $object->can('asString') ) {
    print "<pre>" . $object->asString(1) . "</pre>";
  }
  else {
    $cgi->pldsDump( $object->{data} );
  }
  print "<hr>";
}
#------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  my %params = $obj->getParams();
  
  my $page  =  $params{id}  ?  $context->getObjectById( $params{id} )  :  $context->getUniversalMgr()->newObjectByClassName( $params{className} );
  die "Page object id $params{id} not found" if $params{id} && !$page;
  
  my %localSlots = %{ $params{slots} };
  
  if ($config->get('publisher.unpublishContentFromUnpublishedGridsOnSave') eq 'yes') {
    # Delete slot content from deleted lists/grids
    while (my ($slotId, $slot) = each %localSlots) {
      if ($slot->{override}->{_isListItemSlot}) {
        my ($parentSlotId) = $slotId =~ m{ \A (.+) [.] [^.]+ }xms;
        delete $localSlots{$slotId} if !$localSlots{$parentSlotId} || !$localSlots{$parentSlotId}->{override}->{_isListSlot};
      }
    }
  }
  
  $page->getSlotList()->setLocalSlotsHash(%localSlots);
  $page->setMetaParentId( $params{parentId} );
  $page->setMetaName(     $params{name}     );
  
  foreach my $locale (keys %{ $params{title} }) {
    $page->setCurrentLocale(          $locale  );
    $page->setTitle( $params{title}->{$locale} );
  }
  $page->setTemplateId(   $params{templateId}    ) if $page->isa('O2CMS::Obj::Page'); # XXX do not set templateId on templates
  $page->setPageCachable( $params{cacheThisPage} ) if $page->can('setPageCachable');
  $page->deleteCachedPage()                        if $page->can('deleteCachedPage');
  
  $page->save();
  return {
    id       => $page->getId(),
    name     => $page->getMetaName(),
    parentId => $page->getMetaParentId(),
  };
}
#------------------------------------------------------------------
sub renderSlot {
  my ($obj) = @_;
  my %params = $obj->getParams();
  $cgi->deleteParam('defaultSlots');
  $cgi->deleteParam('slots');
  
  my $page = $obj->_getPage( $params{id} ) or die 'Page object id $params{pageId} not found';
  
  my @ids = ( $params{slotId} );
  $obj->_checkSlots( \%params, \@ids, $page->getUrl() );
  
  $page->getSlotList()->setLocalSlotsHash(    %{ $params{slots}        } );
  $page->getSlotList()->setExternalSlotsHash( %{ $params{defaultSlots} } );
  
  my $pageRenderer = $obj->_getPageRenderer($page);
  $pageRenderer->{parser}->setProperty('reloadingSingleSlot', 1);
  
  my $contentHtml = $pageRenderer->renderSlotContent(
    slotId          => $params{slotId},
    templateMatch   => $params{templateMatch},
    next            => $params{nextSlot},
    defaultTemplate => $params{defaultTemplate},
  );
  
  # nasty hack...? - <script> tags will not execute when set with innerHTML in Mozilla
  my (@js, @jsFiles, @cssFiles);
  $contentHtml =~ s|<script[^>]+src=[\"\'](.+)[\"\'][^>]*>.*?</script>|push @jsFiles, $1;''|ieg;
  $contentHtml =~ s|<link[^>]+ href=[\"\'](.+\.css)[\"\'][^>]*>|push @cssFiles, $1;''|ieg;
  $contentHtml =~ s|<script[^>]*>(.*?)</script>|push @js, $1;''|ieg;
  $obj->_validateHtml($contentHtml);
  
  require URI::Escape;
  URI::Escape->import( qw(uri_escape) );
  $contentHtml = uri_escape($contentHtml, "\0-\377");
  
  return {
    content  => $contentHtml,
    execute  => join (';', @js),
    jsFiles  => join (',', @jsFiles),
    cssFiles => join (',', @cssFiles),
  };
}
#------------------------------------------------------------------
sub renderSlots {
  my ($obj) = @_;
  my %params = $obj->getParams();
  
  my $page = $obj->_getPage( $params{id} );
  
  my $pageRenderer = $obj->_getPageRenderer($page);
  my $slotList = $page->getSlotList();
  $slotList->setLocalSlotsHash(    %{ $params{slots}        } );
  $slotList->setExternalSlotsHash( %{ $params{defaultSlots} } );
  my $slotMgr = $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
  my @externalSlots = $slotMgr->getExternalSlotsByLocalSlots( $slotList->getLocalSlots() );
  $slotList->addExternalSlots(@externalSlots);
  
  my @slotIdsToReload = keys %{ $params{slotsToReload} };
  $obj->_checkSlots( \%params, \@slotIdsToReload, $page->getUrl() );
  
  my @slots;
  foreach my $slot ( values %{ $params{slotsToReload} } ) {
    my $contentHtml = $pageRenderer->renderSlotContent(
      slotId          => $slot->{slotId},
      templateMatch   => $slot->{templateMatch},
      next            => $slot->{nextSlot},
      defaultTemplate => $slot->{defaultTemplate},
    );
    $pageRenderer->{parser}->parse(\$contentHtml); # So that macros will be parsed (error messages, f ex)
    
    my (@js, @jsFiles, @cssFiles);
    $contentHtml =~ s|<script[^>]+src=[\"\'](.+)[\"\'][^>]*>.*?</script>|push @jsFiles, $1;''|ieg;
    $contentHtml =~ s|<link[^>]+ href=[\"\'](.+\.css)[\"\'][^>]*>|push @cssFiles, $1;''|ieg;
    $contentHtml =~ s|<script[^>]*>(.*?)</script>|push @js, $1;''|ieg;
    $obj->_validateHtml($contentHtml);
    
    require URI::Escape;
    URI::Escape->import( qw(uri_escape) );
    $contentHtml = uri_escape($contentHtml, "\0-\377");
    
    push @slots, {
      id       => $slot->{slotId},
      content  => $contentHtml,
      execute  => join (';', @js),
      jsFiles  => join (',', @jsFiles),
      cssFiles => join (',', @cssFiles),
    };
  }
  return {
    slots => \@slots,
  };
}
#------------------------------------------------------------------
sub checkDroppedObject {
  my ($obj) = @_;
  my %params = $obj->getParams();
  my $object = $context->getObjectById( $params{objectId} );
  $obj->_checkObject( $object, $params{slotId}, $params{pageUrl} );
  return {
    test => 1,
  };
}
#------------------------------------------------------------------
sub getImageInfo {
  my ($obj) = @_;
  my %params = $obj->getParams();
  
  my $image = $context->getObjectById( $params{imageId} );
  die "Image object id $params{imageId} not found" unless $image;
  die "Object id $params{imageId} not an image"    unless $image->isa('O2::Obj::Image');
  
  return {
    imageId   => $image->getId(),
    name      => $image->getMetaName(),
    imageUrl  => $image->getScaledUrl( $params{width}, $params{height} ),
    width     => $params{width},
    height    => $params{height},
  };
}
#------------------------------------------------------------------
sub _getPage {
  my ($obj, $pageId) = @_;
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my $page = $pageId ? $context->getObjectById($pageId) : $universalMgr->newObjectByClassName('O2CMS::Obj::Page') or die "Page object id $pageId not found";
  return $page;
}
#------------------------------------------------------------------
sub _getPageRenderer {
  my ($obj, $pageOrPageId) = @_;
  my $page;
  $page = $pageOrPageId if ref $pageOrPageId;
  $page = $obj->_getPage($pageOrPageId) unless $page;
  require O2CMS::Publisher::PageRenderer;
  return O2CMS::Publisher::PageRenderer->new(
    page  => $page,
    media => 'Editor',
  );
}
#------------------------------------------------------------------
sub _checkSlots {
  my ($obj, $args, $slotIds, $pageUrl) = @_;
  foreach my $slotId (@{$slotIds}) {
    my $slot = $args->{slots}->{$slotId};
    $obj->_checkSlot($slot, $slotId, $pageUrl);
  }
  return 'ok';
}
#------------------------------------------------------------------
sub _checkSlot {
  my ($obj, $slot, $slotId, $pageUrl) = @_;
  return 'ok' unless $slot->{contentId};
  
  my $object = $context->getObjectById( $slot->{contentId} );
  return 'ok' unless $object;
  return $obj->_checkObject($object, $slotId, $pageUrl);
}
#------------------------------------------------------------------
sub _checkObject {
  my ($obj, $object, $slotId, $pageUrl) = @_;
  
  if ( $object->isa('O2CMS::Obj::Article') && !$object->isPublishable($pageUrl) ) {
    die $obj->getLang()->getString('o2.pageEditor.errorArticleNotApproved', name => $object->getMetaName(), url => $pageUrl);
  }
  return 'ok';
}
#------------------------------------------------------------------
sub _validateHtml {
  my ($obj, $html) = @_;
  require O2::Template::Critic::Test;
  my $templateTester = O2::Template::Critic::Test->new(
    severity => 4,
    profile  => "$ENV{O2CMSROOT}/bin/tools/critic/.templateCriticRenderSlotRc",
  );
  my $critic = $templateTester->_getCritic();
  my $errorStr = '';
  my $filePath = $config->get('setup.tmpDir') . '/renderSlotValidateHtml.html';
  $context->getSingleton('O2::File')->writeFile($filePath, $html);
  my @violations = $critic->critique($filePath);
  foreach my $violation (@violations) {
    $errorStr .= $violation->toString() . "\n";
  }
  $errorStr = substr $errorStr, 0, -1 if $errorStr;
  die "Unclean HTML:\n\n$errorStr" if @violations;
}
#------------------------------------------------------------------
1;
