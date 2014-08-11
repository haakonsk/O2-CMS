package O2Plugin::Shop::Mgr::Product::CategoryManager;

use strict;
use base 'O2CMS::Mgr::WebCategoryManager';

use O2Plugin::Shop::Obj::Product::Category;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Product::Category',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    name           => { type => 'varchar', multilingual => 1                        },
    description    => { type => 'text',    multilingual => 1                        },
    childObjectIds => { type => 'O2Plugin::Shop::Obj::Product', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
