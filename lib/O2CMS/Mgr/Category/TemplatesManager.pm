package O2CMS::Mgr::Category::TemplatesManager;

use strict;

use base 'O2CMS::Mgr::Template::DirectoryManager';

use O2CMS::Obj::Category::Templates;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Category::Templates',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
