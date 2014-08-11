package O2CMS::Mgr::FlashManager;

use strict;

use base 'O2::Mgr::FileManager';

use O2CMS::Obj::Flash;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Flash',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
