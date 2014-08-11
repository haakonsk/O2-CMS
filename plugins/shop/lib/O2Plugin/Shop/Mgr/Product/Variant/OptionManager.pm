package O2Plugin::Shop::Mgr::Product::Variant::OptionManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Product::Variant::Option;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Product::Variant::Option',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    value              => { type => 'varchar', multilingual => 1            },
    priceModifierExVat => { type => 'varchar'                               },
    variantId          => { type => 'O2Plugin::Shop::Obj::Product::Variant' },
    productId          => { type => 'O2Plugin::Shop::Obj::Product'          },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName( $object->getValue() ) unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
