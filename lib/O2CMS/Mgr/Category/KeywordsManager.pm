package O2CMS::Mgr::Category::KeywordsManager;

use strict;
use base 'O2CMS::Mgr::CategoryManager';

use O2CMS::Obj::Category::Keywords;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Category::Keywords',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
