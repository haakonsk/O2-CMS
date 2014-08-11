package O2Plugin::Shop::Obj::Order;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $config);
use O2::Util::List qw(upush);

#-------------------------------------------------------------------------------
sub addReservation {
  my ($obj, $product, %params) = @_;

  # Get fromDate and toDate
  my $dateFormatter = $context->getDateFormatter();
  my ($fromDate, $toDate);
  $fromDate = $toDate = $dateFormatter->dateFormat( $params{epoch},     'yyyyMMdd' ) if $params{epoch};
  $fromDate =           $dateFormatter->dateFormat( $params{fromEpoch}, 'yyyyMMdd' ) if $params{fromEpoch};
  $toDate   =           $dateFormatter->dateFormat( $params{toEpoch},   'yyyyMMdd' ) if $params{toEpoch};
  $fromDate = $toDate = $params{date}     if $params{date};
  $fromDate =           $params{fromDate} if $params{fromDate};
  $toDate   =           $params{toDate}   if $params{toDate};

  my $datePeriodMgr = $context->getSingleton('O2::Mgr::DatePeriodManager');
  my $datePeriod = $datePeriodMgr->newObject(
    fromDate => $fromDate,
    toDate   => $toDate,
  );

  my (@datePrices, $latestDatePrice);
  foreach my $swedishDate ($datePeriod->getDates()) {
    my $date = $product->getCalendar()->getDate($swedishDate);
    my $priceIncVat = $product->getPriceIncVatForDate($date);
    if ($priceIncVat eq $latestDatePrice->{price}) {
      $latestDatePrice->{toDate} = $swedishDate;
      next;
    }
    $latestDatePrice = {
      price    => $priceIncVat,
      fromDate => $swedishDate,
      toDate   => $swedishDate,
      date     => $date,
    };
    push @datePrices, $latestDatePrice;
  }
  $obj->save() unless $obj->getId(); # We need the id

  my $reservation;
  if ($params{orderLineId}) {
    $reservation = $context->getObjectById( $params{orderLineId} );
  }
  else {
    $reservation = $obj->_getReservationMgr()->newObject();
    $reservation->setMetaName( 'Reservations of product ' . $product->getId() . " from $fromDate to $toDate" );
    $reservation->setOrderId(    $obj->getId()                                   );
    $reservation->setCount(      1                                               ); # XXX Probably not always correct
    $reservation->setProductId(  $product->getId()                               );
    $reservation->setSellerId(   $params{sellerId} || $product->getMetaOwnerId() );
    $reservation->setMetaStatus( 'reserved'                                      );
    $reservation->save(); # Need the id later
  }

  my @reservationPeriodIds;
  foreach my $datePrice (@datePrices) {
    my $reservationPeriod = $reservation->newReservationPeriod(
      fromDate => $datePrice->{fromDate},
      toDate   => $datePrice->{toDate},
    );

    my $metaName = sprintf 'Reservation of product %s from %s to %s', $product->getId(), $reservationPeriod->getFromDate(), $reservationPeriod->getToDate();
    $reservationPeriod->setMetaName(        $metaName                   );
    $reservationPeriod->setUnitPriceIncVat( $datePrice->{price}         );
    $reservationPeriod->setMustPayPerDay(   $params{mustPayPerDay} || 0 );
    $reservationPeriod->save();

    push @reservationPeriodIds, $reservationPeriod->getId();
  }
  $reservation->setReservationPeriodIds(@reservationPeriodIds);
  $reservation->save();
  $obj->addOrderLineId( $reservation->getId() ) unless $params{orderLineId};

  return $reservation;
}
#-----------------------------------------------------------------------------
sub updateReservation {
  my ($obj, $orderLineId, %params) = @_;
  my $orderLine = $context->getObjectById($orderLineId);
  $obj->addReservation(
    $orderLine->getProduct(),
    %params,
    orderLineId => $orderLineId,
  );
}
#-----------------------------------------------------------------------------
sub confirmPurchase {
  my ($obj, $status) = @_;
  foreach my $orderLine ($obj->getOrderLines()) {
    $orderLine->confirmPurchase($status);
  }
  $obj->setStatus( $status || 'confirmed' );
  $obj->save();
}
#-----------------------------------------------------------------------------
sub getPriceExVat {
  my ($obj) = @_;
  my $sum = 0;
  foreach my $orderLine ($obj->getOrderLines()) {
    $sum += $orderLine->getPriceExVat();
  }
  return $sum;
}
#-------------------------------------------------------------------------------
sub getPriceIncVat {
  my ($obj) = @_;
  my $sum = 0;
  foreach my $orderLine ($obj->getOrderLines()) {
    $sum += $orderLine->getPriceIncVat();
  }
  return $sum;
}
#-------------------------------------------------------------------------------
sub getTransaction {
  my ($obj) = @_;
  my $transactionId = $obj->getTransactionId();
  if (!$transactionId) {
    my $transactionMgrClassName = $config->get('shop.transactionMgrClassName');
    my $transaction = $context->getSingleton($transactionMgrClassName)->newObject();
    $transaction->setAmount(  $obj->getPriceIncVat() );
    $transaction->setOrderId( $obj->getId()          );
    return $transaction;
  }
  my $transaction = $context->getObjectById($transactionId);
  die "Could not get transaction with ID $transactionId" unless ref $transaction;
  return $transaction;
}
#-------------------------------------------------------------------------------
sub addOrderLineId {
  my ($obj, $orderLineId) = @_;
  my @orderLineIds = $obj->getOrderLineIds();
  upush @orderLineIds, $orderLineId;
  $obj->setOrderLineIds(@orderLineIds);
}
#-------------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $orderLine ($obj->getOrderLines()) {
    $orderLine->deletePermanently();
  }
  
  my $customer = $obj->getCustomer();
  $customer->deletePermanently() if $customer && ref ($customer) =~ m{ ::Obj::Person \z }xms;
  
  $obj->SUPER::deletePermanently();
}
#-------------------------------------------------------------------------------
sub getExtraInfo {
  my ($obj, $key) = @_;
  my %extraInfos = $obj->getExtraInfos();
  return $extraInfos{$key};
}
#----------------------------------------------------------------------------
sub setExtraInfo {
  my ($obj, $key, $value) = @_;
  my %extraInfos = $obj->getExtraInfos();
  $extraInfos{$key} = $value;
  return $obj->setExtraInfos(%extraInfos);
}
#----------------------------------------------------------------------------
sub getReceiptUrl {
  my ($obj) = @_;
  
  my $receiptClass = $obj->getOrderType()->getReceiptGuiClassName();
  
  $receiptClass =~ s/.+?Gui\:\://;
  $receiptClass =~ s/\:\:/\-/g;
  
  require O2Plugin::Shop::Util::ReceiptChecksum;
  my $receiptUrl = $config->get('dispatcher.dispatcherUrl') . "/$receiptClass/showReceipt?"
    . "orderId=" . $obj->getId() . "&reference=" . O2Plugin::Shop::Util::ReceiptChecksum::checksum( $obj->getId() );
    
  $receiptUrl =~ s{//}{/}g;
  return $receiptUrl;
}
#-------------------------------------------------------------------------------
sub newOrderLine {
  my ($obj, $orderLineClassName) = @_;
  # XXX Add orderLineClassName to orderType so we can handle them from there
  
  $obj->save() unless $obj->getId(); # Need to save the order in order to have an Id

  my $universalMgr = $context->getUniversalMgr();
  $orderLineClassName ||= 'O2Plugin::Shop::Obj::OrderLine';
  my $orderLine = $universalMgr->newObjectByClassName($orderLineClassName);
  $orderLine->setOrderId(  $obj->getId()                 );
  $orderLine->setMetaName( ref $orderLine . " orderline" );
  return $orderLine;
}
#-------------------------------------------------------------------------------
# XXX Or just return getObjectsByIds( $obj->getOrderLineIds() )
sub getOrderLines {
  my ($obj) = @_;
  return () unless $obj->getId();
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLineManager')->getOrderLinesByOrderId( $obj->getId() );
}
#-------------------------------------------------------------------------------
sub getTopLevelOrderLines { #Only return the top layer of orderLines and skip all subOrderLines
  my ($obj) = @_;
  my @allOrderLines = $obj->getOrderLines();
  my @topLevelOrderLines;
  my %allOrderLineIds = map { $_->getId() => 1 } @allOrderLines;
  foreach my $orderLine (@allOrderLines) {
    push @topLevelOrderLines, $orderLine unless $allOrderLineIds{ $orderLine->getMetaParentId() };
  }
  return @topLevelOrderLines;
}
#-------------------------------------------------------------------------------
sub cancelOrderLine {
  my ($obj, $orderLine, $dontDeleteOrder) = @_;
  my $orderLineId = $orderLine->getId();
  my @orderLines  =  grep  { $_->getMetaStatus() ne 'cancelled' }  $obj->getTopLevelOrderLines();
  $orderLine->cancel();
  if (@orderLines == 1  &&  $orderLines[0]->getId() == $orderLineId) {
    # If we deleted the only remaining (non-cancelled) order line, then we delete the order as well.
    # No reason to have an order with no order lines, I guess.
    $obj->cancel() unless $dontDeleteOrder; # Don't want another call to order->delete
  }
}
#-------------------------------------------------------------------------------
sub cancelOrderLines {
  my ($obj, $dontDeleteOrder) = @_;
  foreach my $orderLine ($obj->getOrderLines()) {
    $obj->cancelOrderLine($orderLine, $dontDeleteOrder);
  }
}
#-------------------------------------------------------------------------------
# Setting to a different status depending on whether the order has been paid for or not.
# If it hasn't been paid for, then we just delete it (status=trashed), otherwise we set
# status to cancelled. Orders with status=cancelled will appear in Settlement and provider
# statistics.
sub cancel {
  my ($obj) = @_;
  $obj->cancelOrderLines(1);
  if ($obj->isPaidFor()) {
    $obj->setMetaStatus('cancelled');
    $obj->save();
  }
  else {
    $obj->delete();
  }
}
#-------------------------------------------------------------------------------
sub isPaidFor {
  my ($obj) = @_;
  return 1 if $obj->getMetaStatus() eq 'confirmed' || $obj->getMetaStatus() eq 'cancelled';
  return 0;
}
#-------------------------------------------------------------------------------
sub getPriceExVatExSubOrderLines {
  my ($obj) = @_;
  my $sum = 0;
  foreach my $orderLine ($obj->getTopLevelOrderLines()) {
    $sum += $orderLine->getPriceExVatExSubOrderLines();
  }
  return $sum;
}
#-------------------------------------------------------------------------------
sub getPriceIncVatExSubOrderLines {
  my ($obj) = @_;
  my $sum = 0;
  foreach my $orderLine ($obj->getOrderLines()) {
    $sum += $orderLine->getPriceIncVatExSubOrderLines();
  }
  return $sum;
}
#-------------------------------------------------------------------------------
sub setStatus {
  my ($obj, $status) = @_;
  $obj->setMetaStatus($status) if $status;
}
#-------------------------------------------------------------------------------
sub setMetaStatus {
  my ($obj, $status) = @_;
  if ( $status eq 'confirmed' && !$obj->getConfirmationTime() ) { # If we're setting status to confirmed for the first time
    $obj->setConfirmationTime(time);
  }
  $obj->setModelValue('metaStatus', $status);
}
#-------------------------------------------------------------------------------
sub getStatus {
  my ($obj) = @_;
  return $obj->getMetaStatus();
}
#-------------------------------------------------------------------------------
sub isOnlinePayment {
  my ($obj) = @_;
  return $obj->getTypeOfSale() ne 'manual';
}
#-------------------------------------------------------------------------------
sub getCustomer {
  my ($obj) = @_;
  return unless $obj->getCustomerId();
  return $context->getObjectById( $obj->getCustomerId() );
}
#-------------------------------------------------------------------------------
sub getCustomerFirstName {
  my ($obj) = @_;
  return $obj->getCustomer()->getFirstName();
}
#-------------------------------------------------------------------------------
sub getCustomerMiddleName {
  my ($obj) = @_;
  return $obj->getCustomer()->getMiddleName();
}
#-------------------------------------------------------------------------------
sub getCustomerLastName {
  my ($obj) = @_;
  return $obj->getCustomer()->getLastName();
}
#-------------------------------------------------------------------------------
sub getCustomerFullName {
  my ($obj) = @_;
  my $name =       $obj->getCustomerFirstName();
  $name   .= ' ' . $obj->getCustomerMiddleName() if $obj->getCustomerMiddleName();
  $name   .= ' ' . $obj->getCustomerLastName();
  return $name;
}
#-------------------------------------------------------------------------------
sub getCustomerAddress {
  my ($obj) = @_;
  return $obj->getCustomer()->getAddress();
}
#-------------------------------------------------------------------------------
sub getCustomerPostalCode {
  my ($obj) = @_;
  return $obj->getCustomer()->getPostalCode();
}
#-------------------------------------------------------------------------------
sub getCustomerPostalPlace {
  my ($obj) = @_;
  return $obj->getCustomer()->getPostalPlace();
}
#-------------------------------------------------------------------------------
sub getCustomerTelephone {
  my ($obj) = @_;
  return $obj->getCustomer()->getPhone();
}
#-------------------------------------------------------------------------------
sub getCustomerEmail {
  my ($obj) = @_;
  return $obj->getCustomer()->getEmail();
}
#-------------------------------------------------------------------------------
sub getCustomerCellPhone {
  my ($obj) = @_;
  return $obj->getCustomer()->getCellPhone();
}
#-------------------------------------------------------------------------------
sub getCustomerCountry {
  my ($obj) = @_;
  return $obj->getCustomer()->getCountry();
}
#-------------------------------------------------------------------------------
sub getOrderType {
  my ($obj) = @_;
  my $orderTypeId = $obj->getOrderTypeId();
  return $context->getObjectById($orderTypeId) || $context->getUniversalMgr()->getTrashedObjectById($orderTypeId);
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isCachable {
  return 0;
}
#-------------------------------------------------------------------------------
sub _getReservationMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLine::ReservationManager');
}
#-------------------------------------------------------------------------------
sub getReservationTimeoutValueInSeconds {
  my ($obj) = @_;
  return $obj->getManager()->getReservationTimeoutValueInSeconds();
}
#-------------------------------------------------------------------------------
1;
