package O2Plugin::Shop::Obj::Receipt;

# The customer's receipt should not change even though the product changes.
# When you create a Receipt object for a product, the product's current state is stored.
# To get the value of a field (for the receipt) just invoke the same method as you would
# have invoked on the product.

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

our $AUTOLOAD;

#----------------------------------------------------------------------------
sub AUTOLOAD {
  my ($obj, @params) = @_;
  die if !ref $obj || !$obj->isa(__PACKAGE__);
  my $methodName = $AUTOLOAD;
  $methodName    =~ s{.*:}{}xms;
  return if $methodName eq 'DESTROY';
  die "$obj must be able to getSerializedObject" unless $obj->can('getSerializedObject');
  my $product = $context->getSingleton('O2::Util::Serializer')->unserialize( $obj->getSerializedObject() );
  die "Didn't find method $methodName in $product" unless $product->can($methodName);
  return $product->$methodName(@params);
}
#----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#----------------------------------------------------------------------------
1;
