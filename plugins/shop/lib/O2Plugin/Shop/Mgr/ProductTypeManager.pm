package O2Plugin::Shop::Mgr::ProductTypeManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::ProductType;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::ProductType',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    name          => { type => 'varchar', multilingual => 1                                 },
    vatPercentage => { type => 'float'                                                      },
    variantIds    => { type => 'O2Plugin::Shop::Obj::Product::Variant', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName( $object->getName() ) unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
sub getAvailableProductTypes {
  my ($obj) = @_;
  return $obj->objectSearch();
}
#-----------------------------------------------------------------------------
1;
