package O2CMS::Mgr::Territory::MunicipalityManager;

use strict;

use base 'O2CMS::Mgr::TerritoryManager';

use O2CMS::Obj::Territory::Municipality;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory::Municipality',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# Returns all municipalities in a country
sub getMunicipalitiesByCountryCode {
  my ($obj, $countryCode) = @_;
  die 'Country code missing' unless $countryCode;
  
  my ($country) = $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Country'],
    code       => $countryCode,
  );
  die "No country with code '$countryCode'" unless $country;
  
  return $obj->queryTerritories(
    classNames => ['O2CMS::Obj::Territory::Municipality'],
    codePath   => $country->getCodePath().'%',
  );
}
#-------------------------------------------------------------------------------
1;
