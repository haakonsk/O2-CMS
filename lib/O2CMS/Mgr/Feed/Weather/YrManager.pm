package O2CMS::Mgr::Feed::Weather::YrManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Feed::Weather::Yr;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Feed::Weather::Yr',
    url => { type => 'varchar', notNull => 1 },
  );
}
#-------------------------------------------------------------------------------
1;
