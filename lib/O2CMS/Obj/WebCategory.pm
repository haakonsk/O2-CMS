package O2CMS::Obj::WebCategory;

use strict;

use base 'O2CMS::Obj::Category';

use O2 qw($context);

#-------------------------------------------------------------------------------
# name of directory below documentRoot
sub setDirectoryName {
  my ($obj, $directoryName) = @_;
  # XXX rename directory if both old and new name are set.
  $obj->{originalDirectoryName} = $directoryName unless exists $obj->{originalDirectoryName};
  $obj->setModelValue('directoryName', $directoryName);
}
#-------------------------------------------------------------------------------
# returns full directory path
sub getDirectoryPath {
  my ($obj) = @_;
  return $obj->getManager()->getDirectoryPathByObject( $obj, $obj->getDirectoryName() );
}
#-------------------------------------------------------------------------------
sub canSave {
  my ($obj, $errorMsgRef) = @_;
  my $path = $obj->getDirectoryPath();
  if (!$path) {
    ${$errorMsgRef} = "No directory path found for object " . $obj->getId();
    return 0;
  }
  my $parentPath = $path;
  $parentPath    =~ s{ / [^/]+ /? \z }{}xms;
  if (!-w $parentPath) {
    ${$errorMsgRef} = "$parentPath is not writable";
    return 0;
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
# returns true if you may move this object to $toContainer
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return $toContainer->isa('O2CMS::Obj::WebCategory') || $toContainer->isa('O2CMS::Obj::Trashcan'); # must be placed in a webcategory (or trash)
}
#-------------------------------------------------------------------------------
sub getUrl {
  my ($obj) = @_;
  return $obj->getManager()->getUrlByObject( $obj, $obj->getDirectoryName() );
}
#-------------------------------------------------------------------------------
# list web categories in this category
sub getWebCategories {
  my ($obj) = @_;
  my @children = $obj->getChildren(); # XXX might be optimized
  return grep { $_->isa('O2CMS::Obj::WebCategory') && $_->getMetaStatus() ne 'deleted' } @children;
}
#-------------------------------------------------------------------------------
# remember parentId, so we can detect category move
sub setMetaParentId {
  my ($obj, $parentId) = @_;
  $obj->{originalParentId} = $parentId unless exists $obj->{originalParentId};
  $obj->SUPER::setMetaParentId($parentId);
}
#-------------------------------------------------------------------------------
# returns original parentId. difference between this and getMetaParentId() indicates webcategory was moved
sub getOriginalParentId {
  my ($obj) = @_;
  return $obj->{originalParentId};
}
#-------------------------------------------------------------------------------
# returns original directoryName. difference between this and getDirectoryName() indicates webcategory was renamed
sub getOriginalDirectoryName {
  my ($obj) = @_;
  return $obj->{originalDirectoryName};
}
#-------------------------------------------------------------------------------
sub getFrontpageId {
  my ($obj) = @_;
  my $frontpageMgr = $context->getSingleton('O2CMS::Mgr::FrontpageManager');
  return $frontpageMgr->getFrontpageIdByCategoryId( $obj->getId() );
}
#-------------------------------------------------------------------------------
sub setContentPlds { # Usually inherited
  my ($obj, $plds) = @_;
  $obj->SUPER::setContentPlds($plds);
  $obj->setDirectoryName( $obj->getDirectoryName() ); #to make sure originalDirectoryName get set if empty
}
#-------------------------------------------------------------------------------
1;
