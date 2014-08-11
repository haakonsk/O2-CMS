package O2CMS::Mgr::Territory::WorldManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::World;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::World',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# returns wold object (must obly be one)
sub getWorld {
  my ($obj) = @_;
  my ($world) = $obj->queryTerritories( classNames => ['O2CMS::Obj::Territory::World'] );
  return $world;
}
#-------------------------------------------------------------------------------
1;
