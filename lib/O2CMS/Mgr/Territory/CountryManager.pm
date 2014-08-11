package O2CMS::Mgr::Territory::CountryManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::Country;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::Country',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# Returns country with a countrycode
sub getCountryByCode {
  my ($obj, $code) = @_;
  die 'Missing code parameter' unless $code;
  
  my ($country) = $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Country'],
    code       => $code,
  );
  return $country;
}
#-------------------------------------------------------------------------------
# Returns all countries
sub getCountries {
  my ($obj) = @_;
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Country'],
  );
}
#-------------------------------------------------------------------------------
1;
