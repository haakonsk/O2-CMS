package O2CMS::Publisher::UrlMapper;

# Class for mapping between publisher urls and objects

use strict;

use O2 qw($context $config);

#---------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#---------------------------------------------------------------------------------
# convert url ResolvedUrl object, or undef if not found
sub resolveUrl {
  my ($obj, $url) = @_;
  my $webCategoryMgr = $context->getSingleton('O2CMS::Mgr::WebCategoryManager');
  my ($siteId, @categoryIds) = $webCategoryMgr->getCategoryIdsByUrl($url);
  die "Site object not found for url $url" unless $siteId;

  # populate return object
  require O2CMS::Publisher::ResolvedUrl;
  my $resolvedUrl = O2CMS::Publisher::ResolvedUrl->new();
  $resolvedUrl->setUrl(             $url         );
  $resolvedUrl->setSiteId(          $siteId      );
  $resolvedUrl->setCategoryPathIds( @categoryIds );

  $url =~ s{ \? .* \z        }{}xms; # Remove query string
  $url =~ s{ https?:// [^/]+ }{}xms; # Remove hostname
  if ($url =~ m{ (\d+) [.]\w+ (?: [.]\w+ )? \z}xms) { # object
    $resolvedUrl->setContentObjectId($1);
  }
  else { # frontpage
    my $frontpageId = $context->getSingleton('O2CMS::Mgr::FrontpageManager')->getFrontpageIdByCategoryId( $resolvedUrl->getLastCategoryId() );
    die 'Frontpage object not found' unless $frontpageId;
    $resolvedUrl->setContentObjectId($frontpageId);
  }
  return $resolvedUrl;
}
#---------------------------------------------------------------------------------
# generate a url based on objectId
# params: object           => Object we want url for
#         absolute         => include hostname in url
#         objectPath       => provide path, or part of path to object (useful for symlinks)
sub generateUrl {
  my ($obj, %params) = @_;
  
  my $objectId = $params{object}->getId();
  
  # should all urls be absolute?
  my $useAbsoluteUrls = $config->get('publisher.useAbsoluteUrls');
  $useAbsoluteUrls    = 'yes' if $params{absolute} && $params{absolute} ne 'no';
  
  # figure out what objects are part of the url
  my ($installation, $site, @path) = $obj->_resolveObjectPath(%params);
  return if $installation->isa('O2CMS::Obj::Trashcan');
  
  if (!$site) {
    return 'http://' . $context->getEnv('HTTP_HOST') . "/$objectId.o2" if $useAbsoluteUrls eq 'yes';
    return "/$objectId.o2";
  }
  die "Site object of wrong type: " . ref $site unless $site->isa('O2CMS::Obj::Site');
  
  my $siteUrl = $useAbsoluteUrls eq 'no' ? '/' : $site->getUrl();
  
  # last part of url refers to content
  my $object = pop @path;
  return $siteUrl unless $object; # reference to the site frontpage?
  die '$objectId != ' . $object->getId() if $objectId != $object->getId();
  
  return $object->getUrl() if $object->isa('O2CMS::Obj::Url');
  
  my $isMultilingualSite = @{ $config->get('o2.locales') } >= 2;
  my $cacheExtension
    = !$isMultilingualSite && $context->getSingleton('O2CMS::Publisher::PageCache')->objectIsCachableUnderSite($object, $site) ? '.html'
    :  $isMultilingualSite                                                                                                     ? '.cached'
    :                                                                                                                            ''
    ;
  
  # object is not located below a site
  return "$siteUrl$objectId.o2$cacheExtension" if !$site || !$site->isa('O2CMS::Obj::Site');
  
  # add categories to url
  my $url = $siteUrl;
  foreach my $category (@path) {
    $url .= $category->getDirectoryName() . '/' if $category->isa('O2CMS::Obj::WebCategory');
  }
  
  return $url                                     if $object->isa('O2CMS::Obj::Frontpage');
  return $url . $object->getDirectoryName() . '/' if $object->isa('O2CMS::Obj::WebCategory');
  return $url . $object->getId() . '.o2' . $cacheExtension;
}
#---------------------------------------------------------------------------------
# returns full object path to object. it is possible to override path with $params{objectPath}, containing full or last part of path.
# Path may also point to current url, in that case we try to put together object path by looking for parent of object
sub _resolveObjectPath {
  my ($obj, %params) = @_;

  my $objectId = $params{object}->getId();

  # make sure we have a MetaTreeManager
  $obj->{metaTreeMgr} = $context->getSingleton('O2::Mgr::MetaTreeManager') unless $obj->{metaTreeMgr};

  my @fullPath; # result path

  # full or partial object path supplied?
  my @objectPath = $params{objectPath}  ?  @{ $params{objectPath} }  :  ();
  if (@objectPath) {
    if ( $objectPath[0]->isa('O2CMS::Obj::Installation') ) {
      # objectPath contains full path
      @fullPath = @objectPath;
    }
    else {
      # find objects between installation and first object in path
      my @startPath = $obj->{metaTreeMgr}->getObjectPathTo( $objectPath[0] );
      @fullPath = (@startPath, @objectPath);
    }

    my $objectPathContainsObject = grep { $_->getId() == $objectId } @objectPath;
    if ($objectPathContainsObject) {
      # do not need objects after objectId
      @fullPath = $obj->_removeObjectsAfterId($objectId, @fullPath);
    }
    else {
      @fullPath = $obj->_resolveObjectPathByParentId( $params{object}, @fullPath );
    }
  }

  # use regular object path
  @fullPath = $obj->{metaTreeMgr}->getObjectPath( $params{object} ) unless @fullPath;
  return @fullPath;
}
#---------------------------------------------------------------------------------
# return full path to object if @fullPath contains parent of $objectId, while respecting symlinks
sub _resolveObjectPathByParentId {
  my ($obj, $object, @fullPath) = @_;
  return unless $object;
  
  my @result;
  foreach my $category (@fullPath) {
    push @result, $category;
    # look for parent of symlink target, not symlink
    if ( $category->getRealObject->isa('O2CMS::Obj::Symlink') ) {
      $category = $category->getSymlinkTargetObject();
    }
    # is this category parent of our object? in that case we have found full path
    if ( $category->getId() == $object->getMetaParentId() ) {
      return (@result, $object);
    }
  }
  return; # no parent found
}
#---------------------------------------------------------------------------------
# takes array of objects and removes objects after $removeAfterId
sub _removeObjectsAfterId {
  my ($obj, $removeAfterId, @objects) = @_;
  my @result;
  foreach my $object (@objects) {
    push @result, $object;
    return @result if $object->getId() == $removeAfterId;
  }
  return @result;
}
#---------------------------------------------------------------------------------
1;
