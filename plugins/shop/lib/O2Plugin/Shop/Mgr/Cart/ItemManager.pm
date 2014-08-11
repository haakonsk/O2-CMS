package O2Plugin::Shop::Mgr::Cart::ItemManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Cart::Item;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Cart::Item',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    productId        => { type => 'O2Plugin::Shop::Obj::Product' },
    amount           => { type => 'int',                         },
    variantOptionIds => { type => 'int', listType => 'hash',     },
    unitPriceIncVat  => { type => 'float'                        }, # Optional, product's price is default
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::Cart::Item',
    { name => 'productIdIndex', columns => [qw(productId)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
1;
