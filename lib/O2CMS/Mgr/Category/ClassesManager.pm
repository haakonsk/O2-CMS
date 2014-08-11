package O2CMS::Mgr::Category::ClassesManager;

use strict;
use base 'O2CMS::Mgr::CategoryManager';

use O2CMS::Obj::Category::Classes;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Category::Classes',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
