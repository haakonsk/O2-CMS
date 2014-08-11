package O2CMS::Mgr::Territory::YrPlaceManager;

use strict;
use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::YrPlace;

#-------------------------------------------------------------------------------
# returns all yr places
sub getYrPlaces {
  my ($obj) = @_;
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::YrPlace'],
  );
}
#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::YrPlace',
    latitude  => { type => 'varchar' },
    longitude => { type => 'varchar' },
    xmlUrl    => { type => 'varchar' },
  );
}
#-------------------------------------------------------------------------------
1;
