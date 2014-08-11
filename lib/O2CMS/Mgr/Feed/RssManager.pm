package O2CMS::Mgr::Feed::RssManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Feed::Rss;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Feed::Rss',
    url => { type => 'varchar', notNull => 1 },
  );
}
#-------------------------------------------------------------------------------
1;
