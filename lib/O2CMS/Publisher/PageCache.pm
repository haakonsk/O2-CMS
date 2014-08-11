# Simple page cacher for O2CMS::Obj::FrontPage and other objects
#
# The files under var/page/pagecache contain a list of all the paths/urls that an object is cached on.

package O2CMS::Publisher::PageCache;

use strict;

use O2 qw($context $cgi $config);
use O2::Util::List qw(upush contains);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  $init{_file} = $context->getSingleton('O2::File');
  $init{_data} = $context->getSingleton('O2::Data');
  
  my $cachePath = $context->getSitePath();
  die 'Error with cache history path. Please setup this O2 installation properly' unless -d $cachePath;
  
  $cachePath = "$cachePath/var/cache/pagecache";
  $init{_file}->mkPath($cachePath) unless -d $cachePath;
  $init{charset}   = $cgi ? $cgi->getCharacterSet() : 'utf-8';
  $init{cachePath} = $cachePath;
  return bless \%init, $pkg;
}
#-------------------------------------------------------------------------------
sub isCached {
  my ($obj, $object) = @_;
  return if !$object || !$object->getId();
  
  # Objects might be cached on a frontpage, even though the object's standalone version has't been cached yet or is set to not be cached. Therefore we ask ObjectCacheHandler to help us a bit :-)
  return 1 if $object->getMetaClassName() ne 'O2CMS::Obj::Frontpage' && $context->getSingleton('O2CMS::Publisher::PageCache::ObjectCacheHandler')->isCachedWithinAFrontpage($object);
  
  my @cachePaths = $obj->_getCacheHistoryPathsForObject($object);
  foreach my $path (@cachePaths) {
    return 1 if -e $path;
  }
  return 0;
}
#-------------------------------------------------------------------------------
sub isCachedById {
  my ($obj, $objectId) = @_;
  return $obj->isCached( $context->getObjectById($objectId) );
}
#-------------------------------------------------------------------------------
sub getCachedPathsForObjectId {
  my ($obj, $objectId) = @_;
  return () unless $obj->isCachedById($objectId);

  my @cachedPaths;
  # find files that this object is cached at (aka all html files of this object)
  my @metaCachePaths = $obj->_getCacheHistoryPathsForObjectId($objectId);
  foreach my $path (@metaCachePaths) {
    next unless -e $path;
    
    my $plds = $obj->{_data}->load($path);
    push @cachedPaths, keys %{$plds};
  }
  return wantarray ? @cachedPaths : \@cachedPaths;
}
#-------------------------------------------------------------------------------
sub getCachedPathsForObject {
  my ($obj, $object) = @_;
  return $obj->getCachedPathsForObjectId( $object->getId() );
}
#-------------------------------------------------------------------------------
sub getCacheTime {
  my ($obj, $objectId) = @_;
  return 0 unless $obj->isCachedById($objectId);
  
  my @cachePaths = $obj->_getCacheHistoryPathsForObjectId($objectId);
  my $cacheTime;
  foreach my $path (@cachePaths) {
    next unless -e $path;
    
    $obj->{_data}->load($path);
    my $time = $obj->{_data}->getMetaDataKey('cacheTime');
    $cacheTime = $time if $time > $cacheTime; # Returning most recent time
  }
  return $cacheTime;
}
#-------------------------------------------------------------------------------
sub addToCache {
  my ($obj, $object, $content) = @_;
  return 0 if !$object || !$content || !$object->can('getWebCategory');
  
  my $objectPath = $obj->_getObjectCachePath($object);
  return 0 unless $objectPath;
  
  $obj->_rememberCachedPathForObjectId( $object->getId(), $objectPath );
  return $obj->{_file}->writeEncodedFile( $objectPath, $obj->{charset}, "<!-- fileEncoding=$obj->{charset} -->\n$content" ) if $obj->{charset};
  return $obj->{_file}->writeFile($objectPath, $content);
}
#-------------------------------------------------------------------------------
sub cacheObject {
  my ($obj, $object, $url) = @_;
  $url ||= $object->getDefaultUrl( absolute => 1 );
  $url   = $obj->getUncachedUrl($url);
  my $site = $obj->getSiteFromUrl($url);
  return 0 unless $obj->objectIsCachableUnderSite($object, $site);
  
  my ($content, $isSuccess) = $obj->cacheContentForUrlAndObject($url, $object);
  return $isSuccess;
}
#-------------------------------------------------------------------------------
sub addToCacheById {
  my ($obj, $objectId, $content) = @_;
  return $obj->addToCache( $context->getObjectById($objectId), $content );
}
#-------------------------------------------------------------------------------
sub delCached {
  my ($obj, $object) = @_;
  return 0 if !$object || !$object->getId();

  # If this is an article, let's try to delete all cached frontpages this article is published on
  if (!$object->isa('O2CMS::Obj::Frontpage')) {
    $context->getSingleton('O2CMS::Publisher::PageCache::ObjectCacheHandler')->delCachedFrontpagesWithThisObject($object);
  }

  # find files that this object is cached at (aka all html files of this object)
  my @cachePaths = $obj->_getCacheHistoryPathsForObject($object);
  foreach my $path (@cachePaths) {
    next unless -e $path;
    
    my $plds = $obj->{_data}->load($path);
    foreach my $cachedFile (keys %{$plds}) {
      unlink $cachedFile if -e $cachedFile;
      warn "Couldn't delete cache file: $cachedFile" if -e $cachedFile;
    }
    unlink $path;
    warn "Couldn't delete cache file: $path" if -e $path;
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub regenerateCached {
  my ($obj, $object) = @_;
  return 0 if !$object || !$object->getId();

  # if this is an article, let's try to delete all cached frontpages this article is published on/at
  if (!$object->isa('O2CMS::Obj::Frontpage')) {
    $context->getSingleton('O2CMS::Publisher::PageCache::ObjectCacheHandler')->regenerateCachedFrontpagesWithThisObject($object);
  }

  # find files that this object is cached at (aka all html files of this object)
  my %seenCachePaths;
  foreach my $cacheInfoPath ($obj->_getCacheHistoryPathsForObject($object)) {
    next unless -e $cacheInfoPath;
    
    my $plds = $obj->{_data}->load($cacheInfoPath);
    my $foundCachedUrl = 0;
    foreach my $cachedFile (keys %{$plds}) {
      $seenCachePaths{$cachedFile} = 1;
      my $regenerateSuccess;
      my $url = $obj->getUrlFromFilepath($cachedFile);
      if ($url) {
        $regenerateSuccess = $obj->regenerateCachedFile($url, $object);
        $foundCachedUrl = 1 if $regenerateSuccess;
      }
      if (!$url || !$regenerateSuccess) {
        unlink $cachedFile;
        warn "Couldn't delete cache file: $cachedFile" if -e $cachedFile;
        delete $plds->{$cachedFile};
      }
    }
    if (!$foundCachedUrl) {
      unlink $cacheInfoPath;
      warn "Couldn't delete cache file: $cacheInfoPath" if -e $cacheInfoPath;
    }
    else {
      my $success = $obj->{_data}->save( $cacheInfoPath, $plds, { cacheTime => time } );
      warn "Couldn't save cache file $cacheInfoPath" unless $success;
    }
  }

  my $objectCachePath = eval { $obj->_getObjectCachePath($object) };
  unlink $objectCachePath if $objectCachePath && !$seenCachePaths{$objectCachePath};

  return 1;
}
#-------------------------------------------------------------------------------
sub getUrlFromFilepath {
  my ($obj, $filePath) = @_;
  my ($domain, $url) = $filePath =~ m{ /  ( [^/]*? [.] [^/]*? [.] [^/]*? )  /  (.*) }xms;
  return $obj->getUncachedUrl("http://$domain/$url");
}
#-------------------------------------------------------------------------------
sub getUncachedUrl {
  my ($obj, $url) = @_;
  $url =~ s{               / \z }{/index.cgi}xms;
  $url =~ s{  index [.] html \z }{index.cgi}xms;
  $url =~ s{ [.] o2 [.] html \z }{.o2}xms;
  return $url;
}
#-------------------------------------------------------------------------------
sub regenerateCachedFile {
  my ($obj, $url, $object) = @_;

  return 0 unless $obj->objectIsCachableUnderSite( $object, $obj->getSiteFromUrl($url) );
  my ($content, $isSuccess) = $obj->cacheContentForUrlAndObject($url, $object);

  return 1 if $isSuccess;

  if (my ($errorMessage) = $content =~ m{ <b \s class="o2ApplicationErrorMessage"> (.+?) </b> }xms) {
    warn "Couldn't regenerate cache for url $url: $errorMessage";
  }
  else {
    warn "Couldn't regenerate cache for url $url: $content";
  }
  return 0;
}
#-------------------------------------------------------------------------------
sub cacheContentForUrlAndObject {
  my ($obj, $url, $object) = @_;

  require HTTP::Request;
  my $request = HTTP::Request->new( GET => $url );
  
  require LWP::UserAgent;
  my $userAgent = LWP::UserAgent->new();
  $userAgent->timeout(20);

  my $response = $userAgent->request($request); # The RequestHandler will add to cache if the object's cachable at this url
  return ( $response->content(), $response->is_success() );
}
#-------------------------------------------------------------------------------
sub objectIsCachableUnderSite {
  my ($obj, $object, $site) = @_;
  
  return 0 if  $object->isa('O2CMS::Obj::Frontpage') && !$obj->frontpageCacheIsEnabledForSite(  $site );
  return 0 if !$object->isa('O2CMS::Obj::Frontpage') && !$obj->objectHtmlCacheIsEnabledForSite( $site );
  return 0 if !$object->can('isPageCachable')        || !$object->isPageCachable();
  
  if ($object->can('getPublishableUrls') && $config->get('publisher.allowPublishingPerUrl') eq 'yes') {
    my @sitenames = $object->getPublishableUrls();
    for my $i (0 .. $#sitenames) {
      $sitenames[$i] =~ s{ \A https?://  ( [^/]+ )  .* \z }{$1}xms;
    }
    return 0 unless contains @sitenames, $site->getHostname();
  }
  
  return 1;
}
#-------------------------------------------------------------------------------
sub delCacheById {
  my ($obj, $objectId) = @_;
  my $object;
  eval {
    $object = $context->getObjectById($objectId);
  };
  return $obj->delCached($object) if $object;

  my $fileMgr = $context->getSingleton('O2::File');
  my @files = $fileMgr->scanDirRecursive( $obj->{cachePath}, "^*_$objectId.\\w+\$" );
  my $deleted = 1;
  foreach my $fileName (@files) {
    my $filePath = "$obj->{cachePath}/$fileName";
    $fileMgr->rmFile($filePath);
    $deleted = 0 if -f $filePath; # Ups, file wasn't deleted!
  }
  return $deleted;
}
#-------------------------------------------------------------------------------
sub regenerateCacheById {
  my ($obj, $objectId) = @_;
  my $object = $context->getObjectById($objectId);
  return $obj->regenerateCached($object) if $object;
  
  $obj->delCacheById($objectId); # If the object doesn't exist, we delete it from the cache
}
#-------------------------------------------------------------------------------
sub _rememberCachedPathForObject {
  my ($obj, $object, $path) = @_;
  my @cachePaths = $obj->_getCacheHistoryPathsForObject($object);
  my $plds = {};
  foreach my $cachePath (@cachePaths) {
    $plds = $obj->{_data}->load($cachePath) if -e $cachePath;
    my $newValue = $context->getEnv('REQUEST_URI') || 1;
    if ($plds->{$path} ne $newValue) { # No need to save if there aren't any changes
      $plds->{$path} = $newValue;
      eval {
        $obj->{_data}->save( $cachePath, $plds, { cacheTime => time } );
      };
      if ($@) { # Maybe directory didn't exist, let's create it if it didn't. And then try to save again.
        my ($dir) = $cachePath =~ m{ \A (.*) / }xms;
        $context->getSingleton('O2::File')->mkPath($dir) unless -d $dir;
        $obj->{_data}->save( $cachePath, $plds, { cacheTime => time } );
      }
    }
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub _rememberCachedPathForObjectId {
  my ($obj, $objectId, $path) = @_;
  return $obj->_rememberCachedPathForObject( $context->getObjectById($objectId), $path );
}
#-------------------------------------------------------------------------------
sub _getCacheHistoryPathsForObject {
  my ($obj, $object) = @_;
  my $className = $object->getMetaClassName();
  $className    =~ s{ :: }{-}xmsg;
  my $objectId = $object->getId();
  my @files = $context->getSingleton('O2::File')->scanDirRecursive( $obj->{cachePath}, "^*_$objectId.\\w+\$" );
  @files    = map { "$obj->{cachePath}/$_" } @files;

  # Find file path under the "default" site, and append it to the @files array, if it's not in the array already.
  my $url = $object->getDefaultUrl( absolute => 1 );
  if ($url) {
    my $site = $obj->getSiteFromUrl($url) or die "Didn't find site for $url";
    my $defaultFilePath = "$obj->{cachePath}/" . $site->getHostname() . "/${className}_$objectId.plds";
    upush @files, $defaultFilePath;
  }

  return @files;
}
#-------------------------------------------------------------------------------
sub _getCacheHistoryPathsForObjectId {
  my ($obj, $objectId) = @_;
  return $obj->_getCacheHistoryPathsForObject( $context->getObjectById($objectId) );
}
#-------------------------------------------------------------------------------
sub flushCache {
  my ($obj, $callBackMethod) = @_;
  die 'Not implemented';
}
#-------------------------------------------------------------------------------
sub _getObjectCachePath {
  my ($obj, $object) = @_;
  my $objectPath = $object->getWebCategory()->getDirectoryPath();
  die "$objectPath not writable" unless -w $objectPath;
  
  my $locale = $context->getLocaleCode();
  my $isMultilingualSite = @{ $config->get('o2.locales') } >= 2;
  return "$objectPath/index.html"                               if !$isMultilingualSite && $object->isa('O2CMS::Obj::Frontpage');
  return "$objectPath/index.html.$locale"                       if  $isMultilingualSite && $object->isa('O2CMS::Obj::Frontpage');
  return "$objectPath/" . $object->getId() . '.o2.html'         if !$isMultilingualSite && $object->can('isPageCachable') && $object->isPageCachable();
  return "$objectPath/" . $object->getId() . ".o2.html.$locale" if  $isMultilingualSite && $object->can('isPageCachable') && $object->isPageCachable();
  return;
}
#-------------------------------------------------------------------------------
sub getSiteFromUrl {
  my ($obj, $url) = @_;
  my ($hostname) = $url =~ m{ https?://  ( [^/]+ ) }xms;
  return $context->getSingleton('O2CMS::Mgr::SiteManager')->getSiteByHostname($hostname);
}
#-------------------------------------------------------------------------------
sub frontpageCacheIsEnabledForSite {
  my ($obj, $site) = @_;
  my $value = $site->getPropertyValue('isPageCachable');
  return $value eq 'yes' || $value eq '1';
}
#-------------------------------------------------------------------------------
sub enableFrontpageCacheForSite {
  my ($obj, $site) = @_;
  $site->setPropertyValue('isPageCachable', 'yes');
}
#-------------------------------------------------------------------------------
sub disableFrontpageCacheForSite {
  my ($obj, $site) = @_;
  $site->setPropertyValue('isPageCachable', 'no');
}
#-------------------------------------------------------------------------------
sub enableObjectHtmlCacheForSite {
  my ($obj, $site) = @_;
  $site->setPropertyValue('isObjectCachable', 'yes') if $site->isa('O2CMS::Obj::Site');
}
#-------------------------------------------------------------------------------
sub disableObjectHtmlCacheForSite {
  my ($obj, $site) = @_;
  $site->setPropertyValue('isObjectCachable', 'no') if $site->isa('O2CMS::Obj::Site');
}
#-------------------------------------------------------------------------------
sub objectHtmlCacheIsEnabledForSite {
  my ($obj, $site) = @_;
  my $value = $site->getPropertyValue('isObjectCachable');
  return $value eq 'yes' || $value eq '1';
}
#-------------------------------------------------------------------------------
sub getCachedObjectIds {
  my ($obj, $site) = @_;
  my @ids = $obj->_findAllCachedPages(undef, $site);
  return @ids;
}
#-------------------------------------------------------------------------------
sub getCachedFrontpageIds {
  my ($obj, $site) = @_;
  my @ids = $obj->_findAllCachedPages('O2CMS::Obj::Frontpage', $site);
  return @ids;
}
#-------------------------------------------------------------------------------
sub _findAllCachedPages {
  my ($obj, $className, $site) = @_;
  my $dir = $site  ?  $obj->{cachePath} . '/' . $site->getHostname()  :  $obj->{cachePath};
  return () unless -d $dir; # Nothing cached or caching not on

  my $introspect = $context->getSingleton('O2::Util::ObjectIntrospect');
  $introspect->setClass($className);
  my @classes = ( $className, $introspect->getSubClasses() );

  my @cachedPldsFiles = $context->getSingleton('O2::File')->scanDirRecursive($dir, '.plds$');
  my @cachedIds;
  foreach my $fileName (@cachedPldsFiles) {
    my ($fileClassName) = $fileName =~ m{ /? ([^/]+?) _ }xms;
    $fileClassName      =~ s{ - }{::}xmsg;
    next if  $className && !contains @classes, $fileClassName;
    next if !$className && $fileClassName eq 'O2CMS::Obj::Frontpage'; # Since we've made a separation between frontpages and other objects, frontpages will not be deleted with the rest of the objects.
    
    my ($objectId) = $fileName =~ m{ \A [^_]+ _ (\d+) }xms;
    upush @cachedIds, $objectId;
  }
  return @cachedIds;
}
#-------------------------------------------------------------------------------
1;
