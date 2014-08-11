package O2CMS::Mgr::DraftManager;

use strict;

use base 'O2::Mgr::RevisionedObjectManager';

use O2CMS::Obj::Draft;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Draft',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getDraftByObjectId {
  my ($obj, $revisionedObjectId) = @_;
  my @objects = $obj->objectSearch(
    metaClassName      => 'O2CMS::Obj::Draft',
    revisionedObjectId => $revisionedObjectId,
  );
  return @objects ? $objects[0] : undef;
}
#-------------------------------------------------------------------------------
1;
