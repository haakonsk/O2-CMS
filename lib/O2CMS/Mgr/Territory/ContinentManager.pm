package O2CMS::Mgr::Territory::ContinentManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::Continent;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::Continent',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# returns all continents
sub getContinents {
  my ($obj) = @_;
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Continent'],
  );
}
#-------------------------------------------------------------------------------
1;
