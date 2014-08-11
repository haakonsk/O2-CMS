package O2CMS::Mgr::Territory::CountyManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::County;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::County',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# returns all counties in a country
sub getCountiesByCountryCode {
  my ($obj, $countryCode) = @_;
  die 'Country code missing' unless $countryCode;
  
  my ($country) = $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Country'],
    code       => $countryCode,
  );
  die "No country with code '$countryCode'" unless $country;
  
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::County'],
    codePath   => $country->getCodePath() . '%',
  );
}
#-------------------------------------------------------------------------------
1;
