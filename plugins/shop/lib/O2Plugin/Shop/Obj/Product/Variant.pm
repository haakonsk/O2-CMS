package O2Plugin::Shop::Obj::Product::Variant;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub newProductVariantOption {
  my ($obj) = @_;
  my $productVariantOption = $context->getSingleton('O2Plugin::Shop::Mgr::Product::Variant::OptionManager')->newObject();
  $productVariantOption->setVariantId( $obj->getId() );
  return $productVariantOption;
}
#-----------------------------------------------------------------------------
sub getVariant {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getVariantId() );
}
#-----------------------------------------------------------------------------
sub getProduct {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getProductId() );
}
#-----------------------------------------------------------------------------
1;
