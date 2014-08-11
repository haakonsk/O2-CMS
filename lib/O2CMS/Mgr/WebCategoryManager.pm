package O2CMS::Mgr::WebCategoryManager;

use strict;
use base 'O2CMS::Mgr::CategoryManager';

use O2 qw($context $config);
use O2CMS::Obj::WebCategory;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::WebCategory',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    directoryName => { type => 'varchar', notNull => 1 },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  my $isUpdate = $object->getId() > 0;
  $obj->SUPER::save($object);
  
  $obj->_createFrontpage($object) unless $isUpdate;
  
  # was webcategory object moved?
  my $wasMoved = $object->getMetaParentId() != $object->getOriginalParentId() || $object->getDirectoryName() ne $object->getOriginalDirectoryName();
  if ($isUpdate && $wasMoved) {
    debug "WebCategory move from " . $object->getOriginalParentId() . " to " . $object->getMetaParentId();
    my $fromCategory = $context->getObjectById( $object->getOriginalParentId() );
    my $toCategory   = $context->getObjectById( $object->getMetaParentId()     );
    die "fromCategory or toCategory missing (" . $object->getOriginalParentId() . " to " . $object->getMetaParentId() . ")" if !$fromCategory || !$toCategory;
    
    my $fromPath = $fromCategory->getDirectoryPath() . '/'. $object->getOriginalDirectoryName();
    my $toPath   = $toCategory->getDirectoryPath()   . '/'. $object->getDirectoryName();
    
    # Sometimes a category is created and moved with status inactive, meaning that
    # its web folder will never be created so we need to check that it actually exists
    if (-d $fromPath) {
      debug "WebCategory move from $fromPath to $toPath";
      $context->getSingleton('O2::File')->move($fromPath, $toPath);
    }
  }
  
  require O2CMS::Publisher::PageWriter;
  my $pageWriter = O2CMS::Publisher::PageWriter->new();
  my $path = $object->getDirectoryPath();
  if ($object->getMetaStatus() eq 'active' || $object->getMetaStatus() eq 'new') {
    $context->getSingleton('O2::File')->mkPath($path) if $path && !-d $path;
    $pageWriter->writeFrontpageScript(category => $object);
  }
  else {
    $context->getSingleton('O2::File')->rmFile($path, '-rf');
  }
}
#-------------------------------------------------------------------------------
sub _createFrontpage {
  my ($obj, $webCategory) = @_;
  my $frontpage = $context->getSingleton('O2CMS::Mgr::FrontpageManager')->newObject();
  $frontpage->{restoringFromTrash} = 1 if $webCategory->{restoringFromTrash};
  $frontpage->setMetaParentId( $webCategory->getId() );
    
  my $frontpageName = $config->get('publisher.frontpageNameTemplate') or die "Config value for 'publisher.frontpageNameTemplate' missing";
  $frontpageName    =~ s|\$webcategoryName\$|$webCategory->getMetaName()|ge;
  $frontpage->setMetaName($frontpageName);
  $frontpage->save();
}
#-------------------------------------------------------------------------------
# returns ($siteId, $categoryId1, $categoryId2 ...) based on a url. undef if not found.
# ignores everything after last /
sub getCategoryIdsByUrl {
  my ($obj, $url) = @_;
  $url =~ s|https?://||;
  $url =~ s|\?.*||; # remove query string
  my ($hostname) = $url =~ m{ ([^/:]+?) (?: [:] \d+)? /+ }xms;
  $url =~ s{ \Q$hostname\E /+ }{}xms;
  my @directories = $url =~ m{ ([^/]+?) /+ }xmsg;
  my $siteMgr = $context->getSingleton('O2CMS::Mgr::SiteManager');
  my ($objectId) = $siteMgr->objectIdSearch( hostname => $hostname ); 
  if (!$objectId) {
    my $siteAliases = $config->get('o2.siteAliases') ;
    ($objectId) = $siteMgr->objectIdSearch( hostname => $siteAliases->{$hostname} ) if $siteAliases->{$hostname};
  }

  return unless $objectId;

  my @categoryIds = ($objectId);
  foreach my $directory (@directories) {
    # lookup plain webcategory
    ($objectId) = $obj->objectIdSearch(
      directoryName => $directory,
      metaParentId  => $objectId,
    );
    return unless $objectId; # webcategory was not found
    push @categoryIds, $objectId;
  }
  return @categoryIds;
}
#-------------------------------------------------------------------------------
# returns full directory path to a category. undef if a category doesn't define directoryName
sub getDirectoryPathByObject {
  my ($obj, $object, $lastDirectory) = @_;
  return $obj->_getLocationByObject($object, $lastDirectory, 0);
}
#-------------------------------------------------------------------------------
sub getUrlByObject {
  my ($obj, $object, $lastDirectory) = @_;
  return $obj->_getLocationByObject($object, $lastDirectory, 1);
}
#-------------------------------------------------------------------------------
# (lastDirectory are included because a new category will not have objectId as save time)
sub _getLocationByObject {
  my ($obj, $object, $lastDirectory, $isUrl) = @_;

  return unless $lastDirectory; # category is not a web folder
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my ($installation, $site, @categories) = $metaTreeMgr->getObjectPathTo($object);
  return unless $site; # category does not reside below a site
  
  my $path = $isUrl ? $site->getUrl() : $site->getDirectoryPath() . '/';
  foreach my $category (@categories) {
    return unless $category->isa('O2CMS::Obj::WebCategory') && $category->getDirectoryName();
    $path .= $category->getDirectoryName() . '/';
  }

  $path .= $lastDirectory;
  $path .= '/' if $isUrl;
  return $path;
}
#-------------------------------------------------------------------------------
# remove object from database
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  my $object;
  eval {
    $object = $context->getObjectById($objectId);
  };
  if ($object) {
    foreach my $child ($object->getChildren()) {
      next unless $child;
      $child->deletePermanently();
    }
    my $directoryPath = $object->getDirectoryPath();
    if (-d $directoryPath) {
      if (-1 == index $context->getEnv('O2CUSTOMERROOT'), $directoryPath) { # Make sure not to remove entire customer root or more
        $context->getSingleton('O2::File')->rmFile($directoryPath, '-rf');
      }
    }
    else {
      warn "Directory-path $directoryPath does not exist (or isn't a directory)";
    }
  }
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-------------------------------------------------------------------------------
1;
