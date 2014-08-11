package O2CMS::Mgr::Template::DirectoryManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2CMS::Obj::Template::Directory;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template::Directory',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    path          => { type => 'varchar', notNull => 1 },
    templateClass => { type => 'varchar'               },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getObjectByPath {
  my ($obj, $path) = @_;
  my @objects = $obj->objectSearch(
    path => $path,
  );
  return unless @objects;
  return $objects[0];
}
#-------------------------------------------------------------------------------
1;
