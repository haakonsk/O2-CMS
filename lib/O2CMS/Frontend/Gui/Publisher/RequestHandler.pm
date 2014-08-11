package O2CMS::Frontend::Gui::Publisher::RequestHandler;

use strict;

use base 'O2::Gui';

use constant DEBUG => 0;
use O2 qw($context $cgi $config);

#--------------------------------------------------------------------------------------------
sub objectRequest {
  my ($obj) = @_;
  
  my $localeCode = $context->getLocaleCode();
  $cgi->addHeader( 'Content-Language', lc substr $localeCode, 0, 2 );
  
  # url from index.cgi handler or dispatcher
  my $url = $context->getEnv('O2REQUESTURL') || '';
  debug "Environment variable O2REQUESTURL contains $url";
  debug 'Request filename: ' . $context->getEnv('REQUEST_URI');
  $url = "http://" . ( $context->getEnv('HTTP_HOST') || $context->getEnv('SERVER_NAME') ) . $context->getEnv('O2REQUESTPATH') unless $url;
  debug "url is $url";
  
  if ($obj->getParam('cached')) {
    my $path = $context->getEnv('DOCUMENT_ROOT') . $context->getEnv('O2REQUESTPATH') . ".html.$localeCode";
    if (-f $path) {
      debug "Fetching HTML from cache: $path";
      return print $context->getSingleton('O2::File')->getFile($path);
    }
    else {
      debug "Wanted to get HTML from cache, but wasn't cached";
    }
  }
  
  # handle site aliases
  my $aliases = $config->get('publisher.siteAliases') || {};
  foreach my $alias (keys %{$aliases}) {
    $url =~ s|\/\/$alias\/|\/\/$aliases->{$alias}\/|;
  }

  # resolve object
  debug "Resolve $url";
  require O2CMS::Publisher::UrlMapper;
  my $urlMapper = O2CMS::Publisher::UrlMapper->new();
  my $resolvedUrl = eval {
    return $urlMapper->resolveUrl($url);
  };
  die "Unable to resolve url \"$url\": $@" if $@;
  debug $resolvedUrl->asString();

  my $object     = $context->getObjectById( $resolvedUrl->getContentObjectId() ) or die 'Object does not exist';
  my $realObject = $object->isa('O2CMS::Obj::Draft') ? $object->getUnserializedObject() : $object;
  
  if ( (!$object->isPublishable($url) || !$realObject->isPublishable($url)) && (!$obj->getParam('preview') || !$context->getBackendSession()) ) {
    return $realObject->handleNotPublishable() if $realObject->can('handleNotPublishable');
    die 'Object not published';
  }

  if ( $object->isa('O2::Obj::File') ) { # We had a case where files where mapped directly to rootlevel - redirect to File-Download instead
    $cgi->redirect( '/o2/File-Download/download?objectId=' . $object->getId() );
    return;
  }

  # create a O2CMS::Obj::Page
  debug sprintf 'Object name: %s, id: %d, class: %s', $object->getMetaName(), $object->getId(), $object->getMetaClassName();
  my $page;
  if ( $object->isa('O2CMS::Obj::Page') ) {
    $page = $object;
  }
  else {
    debug "Create page object on the fly";
    # create a page object on the fly
    $page = $context->getSingleton('O2CMS::Mgr::PageManager')->newObject();
    $page->setMetaParentId( $resolvedUrl->getLastCategoryId() );
    # lookup page template in property
    my $realObjectClassName = $realObject->getMetaClassName();
    my $pageTemplateId = $obj->_getPageTemplateId( $resolvedUrl->getLastCategoryId(), $realObjectClassName );
    $pageTemplateId  ||= $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectByPath('/Templates/pages/blank.html')->getId();
    debug "pageTemplateId from property: $pageTemplateId";
    die $obj->getLang()->getString( 'o2.desktop.errorPageTemplateIdMissing', className => $object->getMetaClassName(), name => $object->getMetaName() ) unless $pageTemplateId;
    $page->setTemplateId($pageTemplateId);
    # lookup template for content in property
    my $objectTemplateId = $obj->_getObjectTemplateId( $resolvedUrl->getLastCategoryId(), $realObjectClassName );
    if (!$objectTemplateId) {
      my @objectTemplatesAssociatedWithClass = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager')->queryTemplates( class => $realObjectClassName );
      if (@objectTemplatesAssociatedWithClass == 1) {
        $objectTemplateId = $objectTemplatesAssociatedWithClass[0]->getId() || '';
      }
    }
    debug 'objectTemplateId from property: ' . (defined $objectTemplateId ? $objectTemplateId : '');
    die "Can't find objectTemplateId property for class $realObjectClassName" unless $objectTemplateId;
    # create content slot in page
    my $slotList = $page->getSlotList();
    $slotList->setLocalSlotsHash(
      content => {
        templateId => $objectTemplateId,
        contentId  => $realObject->getId() || $object->getId(), # If we're previewing an article, realObject may not have an ID yet (if it hasn't been saved)
      },
    );
  }

  $page->setResolvedUrl($resolvedUrl);

  debug 'site: '        . $page->getSite();
  debug 'webCategory: ' . $page->getWebCategory();

  require O2CMS::Publisher::PageRenderer;
  my $pageRenderer = O2CMS::Publisher::PageRenderer->new(
    page  => $page,
    media => 'Html',
  );

  my %q = $obj->getParams();
  $pageRenderer->setTemplateVariable( q      => \%q                    );
  $pageRenderer->setTemplateVariable( object => $realObject            );
  $pageRenderer->setTemplateVariable( ENV    => { $context->getEnv() } );

  my $html = ${ $pageRenderer->renderPage() };

  # If caching is enabled at all on this installation, let's check if we can cache the current page 
  my $pageCacher = $context->getSingleton('O2CMS::Publisher::PageCache');
  if ($pageCacher->objectIsCachableUnderSite( $object, $page->getSite() )) {
    debug 'Object is cachable';
    $page->setId( $object->getId() ) if !$page->getId() || !($page->getId() > 0);
    my $cacheStamp = "\n<!-- O2 Cached at: " . (scalar localtime time) . ' -->';
    $html .= $cacheStamp;
    $pageCacher->addToCache($page, $html);
    debug "IS CACHED at " . scalar localtime time;
  }
  print $html;
}
#--------------------------------------------------------------------------------------------
sub _getPageTemplateId {
  my ($obj, $category, $className) = @_;
  return $obj->_getTemplateId('pageTemplateId', $category, $className);
}
#--------------------------------------------------------------------------------------------
sub _getObjectTemplateId {
  my ($obj, $categoryId, $className) = @_;
  return $obj->_getTemplateId('objectTemplateId', $categoryId, $className);
}
#--------------------------------------------------------------------------------------------
sub _getTemplateId {
  my ($obj, $propertyNamePrefix, $categoryId, $className) = @_;
  my @classNames = ($className);
  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspector->setClass($className);
  push @classNames, $introspector->getInheritedClasses();

  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  foreach my $class (@classNames) {
    my $objectTemplateId = $propertyMgr->getPropertyValue($categoryId, "$propertyNamePrefix.$class");
    return $objectTemplateId if $objectTemplateId;
  }
  return;
}
#--------------------------------------------------------------------------------------------
1;
