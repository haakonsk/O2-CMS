package O2Plugin::Shop::Gui::Functionality::Order;

use strict;

use O2 qw($context $cgi $session);

#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _saveCustomerInfo {
  my ($obj) = @_;
  my $order = $obj->_getOrderFromSession();
  die "No order found in session!" unless $order;

  require O2::Util::AccessorMapper;
  my $accessorMapper = O2::Util::AccessorMapper->new();
  $accessorMapper->setAccessors( $order, %{ $cgi->getStructure('order') });
  $order->save();

  return $order;
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _redirectUserToPayment {
  my ($obj, %params) = @_;

  my $paymentUrl = $obj->_generatePaymentUrl(%params);
  die "Transaction did not return a paymentUrl" unless $paymentUrl;

  $cgi->redirect($paymentUrl);
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _generatePaymentUrl {
  my ($obj, %params) = @_;
  my $order = delete $params{order} || $obj->_getOrderFromSession();
  
  die "No order supplied or found in session!" unless $order;
  die "$order is not an order object"          unless $order->isa('O2Plugin::Shop::Obj::Order');

  my $transaction = $obj->_getTransactionManager()->newObject();
  my $paymentUrl  = $transaction->generatePaymentUrl(
    amount    => exists $params{amount} ? $params{amount} : $order->getPriceIncVatExSubOrderLines(),
    returnUrl => $obj->_getPaymentReturnUrl(),
    orderId   => $order->getId(),
    %params,
  );

  $order->setTransactionId( $transaction->getId() );
  $order->save();

  return $paymentUrl;
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _redirectUserToReceipt {
  my ($obj, $order) = @_;
  $order ||= $obj->_getOrderFromSession();
  die "No order found in session!" unless $order;

  $cgi->redirect( $obj->_generateReceiptUrlFromOrder($order) );
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _handleReceivedPayment {
  my ($obj) = @_;
  my $order = $obj->_getOrderFromSession();
  if (!$order && $obj->getParam('transactionId')) {
    my $orderMgr = $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager');
    $order = $orderMgr->getOrderByTransactionId( $obj->getParam('transactionId') );
    $obj->_saveOrderIdToSession( $order->getId() ) if $order;
  }
  die "No order found in session, and no valid transactionId supplied!" unless $order;
  
  $order->setStatus( $order->getTransaction()->receivePayment() ? 'confirmed' : 'failedToReceivePayment' );
  $order->save();
  return $order;
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _generateReceiptUrlFromOrder {
  my ($obj, $order) = @_;
  my $orderType = $order->getOrderType();
  my $className = $orderType->getReceiptGuiClassName();
  $className    =~ s/::/-/g;
  my %params = (
    orderId   => $order->getId(),
    reference => $obj->_receiptSecurityReference( $order->getId() ),
  );
  
  return $obj->getSingleton('O2::Util::UrlMod')->urlMod(
    setClass  => $className,
    setMethod => 'showReceipt',
    setParams => \%params,
  );
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _receiptSecurityReference {
  my ($obj, $id) = @_;
  require O2Plugin::Shop::Util::ReceiptChecksum;
  return O2Plugin::Shop::Util::ReceiptChecksum::checksum($id);
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _getTransactionManager {
  die "Abstract method '_getTransactionManager' called";
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _getPaymentClassMethod {
  die "Abstract method '_getPaymentClassMethod' called";
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _getPaymentReturnUrl {
  my ($obj) = @_;
  return $obj->getSingleton('O2::Util::UrlMod')->urlMod(
    setMethod    => $obj->_getPaymentClassMethod(),
    removeParams => 1,
    absoluteURL  => 1,
  );
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _getCustomerId {
  my ($obj) = @_;
  my $user = $session->get('user');
  my $userId = $user ? $user->{userId} : undef;
  return $userId;
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _saveOrderIdToSession {
  my ($obj, $orderId) = @_;
  $session->set( currentOrderId => $orderId );
  $session->save();
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _clearSessionOrder {
  my ($obj) = @_;
  $obj->_saveOrderIdToSession( undef );
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _getOrderFromSession {
  my ($obj) = @_;
  my $orderId = $session->get('currentOrderId');
  return unless $orderId;

  my $order = $context->getObjectById($orderId);
  return if !$order || !$order->isa('O2Plugin::Shop::Obj::Order');
  return $order;
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
sub _newOrderByOrderTypeId {
  my ($obj, $orderTypeId) = @_;
  return $context->getObjectById($orderTypeId)->newOrderObject();
}
#-----------------------------------------------------------------------------------------------------------------------------------------------
1;
