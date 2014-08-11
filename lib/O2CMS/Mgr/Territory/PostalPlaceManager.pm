package O2CMS::Mgr::Territory::PostalPlaceManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::PostalPlace;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::PostalPlace',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# returns all postal places in a country
sub getPostalPlacesByCountryCode {
  my ($obj, $countryCode) = @_;
  die 'Country code missing' unless $countryCode;
  
  my ($country) = $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Country'],
    code       => $countryCode,
  );
  die "No country with code '$countryCode'" unless $country;
  
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::PostalPlace'],
    codePath   => $country->getCodePath.'%',
  );
}
#-------------------------------------------------------------------------------
1;
