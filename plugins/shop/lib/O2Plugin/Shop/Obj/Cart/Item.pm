package O2Plugin::Shop::Obj::Cart::Item;

use strict;
use base 'O2::Obj::Object';

#--------------------------------------------------------------------------------------------------
sub getUnitPriceIncVat {
  my ($obj) = @_;
  my $price = $obj->getModelValue('unitPriceIncVat');
  return $price if $price;

  my $product = $obj->getProduct();
  die "Didn't find product for cart item ", $obj->getId() unless $product;
  return $product->getPriceIncVat();
}
#--------------------------------------------------------------------------------------------------
1;
