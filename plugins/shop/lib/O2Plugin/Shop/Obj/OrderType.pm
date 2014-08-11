package O2Plugin::Shop::Obj::OrderType;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-------------------------------------------------------------------------------
# Listers for associated data
sub getOrderIds {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->objectIdSearch(
    orderTypeId => $obj->getId(),
  );
}
#-------------------------------------------------------------------------------
sub newOrderObject {
  my ($obj) = @_;
  my $order = $context->getSingleton('O2::Mgr::UniversalManager')->newObjectByClassName( $obj->getOrderClassName() );
  $order->setOrderTypeId( $obj->getId() );
  $order->setStatus(      'created'     );
  return $order;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  my ($obj) = @_;
  return 0 if $obj->getOrderIds(); # If we're in use, we can't be deleted
  return 1;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
1;
