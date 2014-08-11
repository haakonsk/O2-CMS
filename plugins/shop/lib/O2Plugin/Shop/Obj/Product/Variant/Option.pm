package O2Plugin::Shop::Obj::Product::Variant::Option;

use strict;
use base 'O2::Obj::Object';

#-----------------------------------------------------------------------------
sub setPriceModifierExVat {
  my ($obj, $priceModifier) = @_;
  $obj->_validatePriceModifier($priceModifier);
  return $obj->setModelValue('priceModifierExVat', $priceModifier);
}
#-----------------------------------------------------------------------------
sub setPriceModifierIncVat {
  my ($obj, $priceModifier) = @_;
  $obj->{priceModifierIncVat} = $priceModifier;
}
#-----------------------------------------------------------------------------
sub getPriceModifierIncVat {
  my ($obj) = @_;
  return $obj->{priceModifierIncVat} if $obj->{priceModifierIncVat};
  my ($how, $amount) = $obj->_validatePriceModifier( $obj->getPriceModifierExVat() );
  return "$how$amount" if $how eq '*' || $how eq '/';
  my $product = $obj->getProduct();
  die "Can't convert from priceModifierExVat to priceModifierIncVat without being able to get the vatPercentage from the product.";
  $amount  *=  ( 100+$product->getVatPercentage() )  /  100;
  return "$how$amount";
}
#-----------------------------------------------------------------------------
sub _validatePriceModifier {
  my ($obj, $priceModifier) = @_;
  my ($how, $amount) = $priceModifier =~ m{ \A  ( [-+/*] )  (.+)  \z }xms;
  $amount =~ s{,}{.}xmsg;
  die "Price modifier ($priceModifier) not valid" if !$how  ||  $amount ne 1*$amount  ||  ($how eq '/' && $amount == 0);
  return ($how, $amount);
}
#-----------------------------------------------------------------------------
sub getModifiedPriceExVat {
  my ($obj, $originalPrice) = @_;
  return eval "$originalPrice" . $obj->getPriceModifierExVat();
}
#-----------------------------------------------------------------------------
1;
