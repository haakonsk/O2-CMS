package O2CMS::Mgr::TrashcanManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2 qw($db);
use O2CMS::Obj::Trashcan;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Trashcan',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub emptyTrash {
  my ($obj, $trashcanId) = @_;
  my $trashcan = $obj->getObjectById($trashcanId);
  return $trashcan->emptyTrash();
}
#-------------------------------------------------------------------------------
sub restoreFromTrash {
  my ($obj, $trashcanId, $objectId) = @_;
  my $trashcan = $obj->getObjectById($trashcanId);
  return $trashcan->restoreFromTrash($objectId);
}
#-------------------------------------------------------------------------------
# remove object from database
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  $db->sql('delete from O2CMS_OBJ_TRASHCAN_CONTENT where objectId=?', $objectId);
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-------------------------------------------------------------------------------
1;
