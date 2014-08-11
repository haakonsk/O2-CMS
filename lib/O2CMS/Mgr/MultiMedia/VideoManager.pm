package O2CMS::Mgr::MultiMedia::VideoManager;

use strict;

use base 'O2::Mgr::FileManager';

use O2CMS::Obj::MultiMedia::Video;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::MultiMedia::Video',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    type => { type => 'varchar', length => '255' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
