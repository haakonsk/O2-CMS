package O2Plugin::Shop::Mgr::ProductManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2Plugin::Shop::Obj::Product;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;

  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Product',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    name                 => { type => 'varchar', multilingual => 1                                                                                       },
    isActive             => { type => 'bit'                                                                                                              },
    defaultPriceExVat    => { type => 'float'                                                                                                            },
    summary              => { type => 'text',    multilingual => 1                                                                                       },
    description          => { type => 'text',    multilingual => 1                                                                                       },
    variantOptionIds     => { type => 'O2Plugin::Shop::Obj::Product::Variant::Option', listType => 'array', testValueMethod => 'getTestVariantOptionIds' },
    imageIds             => { type => 'O2::Obj::Image', listType => 'array'                                                                              },
    links                => { type => 'varchar', listType => 'hash'                                                                                      },
    associatedProductIds => { type => 'O2Plugin::Shop::Obj::Product', listType => 'array'                                                                },
    includedProductIds   => { type => 'O2Plugin::Shop::Obj::Product', listType => 'hash'                                                                 },
    attributes           => { type => 'text', listType => 'hash'                                                                                         },
    productId            => { type => 'varchar'                                                                                                          },
    productTypeId        => { type => 'O2Plugin::Shop::Obj::ProductType', testValueMethod => 'getTestProductTypeId'                                      },
    priceIncVat          => { type => 'float'                                                                                                            }, # is used when productTypeId is null
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::Product',
    { name => 'productIdIndex',     columns => [qw(productId)],     isUnique => 0 },
    { name => 'productTypeIdIndex', columns => [qw(productTypeId)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub getAllProducts {
  my ($obj) = @_;
  my @productIds = $db->selectColumn( 'select objectId from O2PLUGIN_SHOP_OBJ_PRODUCT' );
  my @products;
  foreach my $productId (@productIds) {
    my $product = $context->getObjectById($productId);
    push @products, $product if $product;
  }
  return \@products;
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $obj->indexForSearch($object, 'o2Shop') if $object->getId();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
sub getTestProductTypeId {
  my $productType = $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->newObject();
  $productType->setMetaName('Product type for test script');
  $productType->save();
  
  my $productTypeId = $productType->getId();
  push @O2::Script::Test::Common::TEST_OBJECT_IDS, $productTypeId;
  return $productTypeId;
}
#-----------------------------------------------------------------------------
sub getTestVariantOptionIds {
  my $optionMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Product::Variant::OptionManager');
  my $option1 = $optionMgr->newObject();
  my $option2 = $optionMgr->newObject();
  $option1->setMetaName('Variant option 1 for test script');
  $option2->setMetaName('Variant option 2 for test script');
  $option1->save();
  $option2->save();
  
  my $option1Id = $option1->getId();
  my $option2Id = $option2->getId();
  push @O2::Script::Test::Common::TEST_OBJECT_IDS, $option1Id, $option2Id;
  return ($option1Id, $option2Id);
}
#-----------------------------------------------------------------------------
1;
