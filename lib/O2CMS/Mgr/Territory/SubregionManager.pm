package O2CMS::Mgr::Territory::SubregionManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::Subregion;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::Subregion',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# returns all subregions
sub getSubregions {
  my ($obj) = @_;
  return $obj->queryTerritories( classNames => ['O2CMS::Obj::Territory::Subregion'] );
}
#-------------------------------------------------------------------------------
1;
