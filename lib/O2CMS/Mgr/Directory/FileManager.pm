package O2CMS::Mgr::Directory::FileManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context);
use O2CMS::Obj::Directory::File;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Directory::File',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    filename    => { type => 'varchar'       },
    importEpoch => { type => 'epoch'         },
    file        => { type => 'O2::Obj::File' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  my $object = $context->getObjectById($objectId);
  my $file = $object->getFile(); # O2::Obj::File object
  $file->deletePermanently();
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-----------------------------------------------------------------------------
1;
