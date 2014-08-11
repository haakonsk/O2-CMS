package O2CMS::Mgr::DirectoryManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2CMS::Obj::Directory;

#--------------------------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Directory',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    path         => { type => 'varchar', notNull => 1                                                                   },
    newAction    => { type => 'varchar', defaultValue => 'create'                                                       },
    changeAction => { type => 'varchar', defaultValue => 'overwrite', validValues => ['overwrite', 'createNew', 'none'] },
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------------------------------------
sub getObjectByPath {
  my ($obj, $path) = @_;
  my @objects = $obj->objectSearch( path => $path );
  die "More than one directory with path $path" if @objects > 1;
  return @objects ? $objects[0] : undef;
}
#--------------------------------------------------------------------------------------------------
1;
