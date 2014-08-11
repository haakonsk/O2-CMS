package O2CMS::Obj::Trashcan;

use strict;

use base 'O2::Obj::Container';

use O2 qw($context $db);
#-------------------------------------------------------------------------------
sub trashObject {
  my ($obj, $object, $isRecursive) = @_;
  return 1 if $object->isTrashed();
  
  $context->startTransaction();
  
  if ($object->isContainer() && !$object->isa('O2::Obj::Object::Query')) { # XXX What about deletion of symlinks, lists etc.
    foreach my $child ($object->getChildren()) {
      next if $child->isTrashed(); # is already trashed
      $obj->trashObject($child, 1); # Recursive call
    }
  }
  
  $db->insert(
    'O2CMS_OBJ_TRASHCAN_CONTENT',
    objectId        => $obj->getId() || 0,
    removedObjectId => $object->getId(),
    originalStatus  => $object->getMetaStatus(),
    removeTime      => time,
    userId          => $context->getUserId() || 0
  );
  
  $object->{preDeleteStatus} = $object->getMetaStatus();
  $object->setMetaStatus($isRecursive ? 'trashedAncestor' : 'trashed');
  
  my $saveResult = $object->save();
  
  delete $object->{preDeleteStatus};
  $context->endTransaction();
  return $saveResult;
}
#-------------------------------------------------------------------------------
sub emptyTrash { # Rewritten to run much faster (hack).
  my ($obj) = @_;
  my @ids = $db->selectColumn("select removedObjectId from O2CMS_OBJ_TRASHCAN_CONTENT where objectId = ?", $obj->getId());
  $db->sql("update O2_OBJ_OBJECT set status = 'deleted' where objectId in (??)", \@ids);
  return 1;
}
#-------------------------------------------------------------------------------
sub restoreFromTrash {
  my ($obj, $objectId, $isRecursive) = @_;
  my ($originalStatus) = $db->fetch( "select originalStatus from O2CMS_OBJ_TRASHCAN_CONTENT where objectId = ? and removedObjectId = ?", $obj->getId(), $objectId );
  my $object           = $context->getSingleton('O2::Mgr::UniversalManager')->getTrashedObjectById($objectId);
  return unless $object->isTrashed();
  return if $isRecursive && $object->getMetaStatus() eq 'trashed'; # Was trashed before its container was trashed, so don't restore!
  
  $object->{restoringFromTrash} = 1;
  $object->setMetaStatus($originalStatus);
  eval {
    $object->save();
  };
  warning 'Error while restoring object with id ' . $object->getId() . ", continuing anyway.. Reason: $@" if $@;
  
  $db->sql( "delete from O2CMS_OBJ_TRASHCAN_CONTENT where objectId = ? and removedObjectId = ?", $obj->getId(), $objectId );
  if ($object->isContainer() ) {
    my @rows = $db->fetchAll("select objectId from O2_OBJ_OBJECT where parentId = ?", $objectId);
    foreach my $row (@rows) {
      $obj->restoreFromTrash( $row->{objectId}, 1 ); # Recursive call
    }
  }
  return $context->getObjectById($objectId);
}
#-------------------------------------------------------------------------------
sub addObject {
  my ($obj, $fromContainer, $addedObject) = @_;
  return $addedObject->delete();
}
#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isDeletable(); # can only move deleteable objects to trash
}
#-------------------------------------------------------------------------------
sub canRemoveObject {
  return 1;
}
#-------------------------------------------------------------------------------
sub getChildren {
  my ($obj, $skip, $limit) = @_;

  my @objects;
  my $universalMgr = $context->getUniversalMgr();

  my $query = "select distinct(removedObjectId) from O2CMS_OBJ_TRASHCAN_CONTENT c, O2_OBJ_OBJECT o where c.removedObjectId = o.objectId and o.status like 'trashed%' and c.objectId = ?";
  my $sth = $db->limitSelect( $query, $skip, $limit, $obj->getId() );
  while ( my ($id) = $sth->next() ) {
    my $object = $universalMgr->getTrashedObjectById($id) or next;
    push @objects, $object if $object->isTrashed() && !$obj->_hasTrashedParent( $object->getId() );
  }
  return @objects;
}
#-------------------------------------------------------------------------------
sub _hasTrashedParent {
  my ($obj, $objectId) = @_;
  my $query = "
    select obj.objectId
    from   O2CMS_OBJ_TRASHCAN_CONTENT trash, O2_OBJ_OBJECT obj
    where  obj.objectId = ?
             and obj.objectId = trash.removedObjectId
             and obj.parentId in (select removedObjectId from O2CMS_OBJ_TRASHCAN_CONTENT)";
  my @rows = $db->fetchAll($query, $objectId);
  return @rows > 0;
}
#-------------------------------------------------------------------------------
1;
