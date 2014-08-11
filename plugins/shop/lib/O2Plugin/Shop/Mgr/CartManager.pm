package O2Plugin::Shop::Mgr::CartManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Cart;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Cart',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    itemIds => { type => 'O2Plugin::Shop::Obj::Cart::Item', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
