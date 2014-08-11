package O2CMS::Mgr::MultiMedia::AudioManager;

use strict;

use base 'O2::Mgr::FileManager';

use O2CMS::Obj::MultiMedia::Audio;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::MultiMedia::Audio',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    type => { type => 'varchar', length => '255' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
