package O2Plugin::Shop::Obj::OrderLine;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isCachable {
  return 0;
}
#----------------------------------------------------------------------------
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
sub deleteExtraInfo {
  my ($obj, $key) = @_;
  my %extraInfos = $obj->getExtraInfos();
  delete $extraInfos{$key};
  return $obj->setExtraInfos(%extraInfos);
}
#----------------------------------------------------------------------------
sub newReservation {
  my ($obj) = @_;
  my $reservation = $obj->_getReservationMgr()->newObject();
  $reservation->setOrderLineId( $obj->getId() );
  return $reservation;
}
#----------------------------------------------------------------------------
sub getReservations {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getReservationIds() );
}
#----------------------------------------------------------------------------
sub getSubOrderLineIds {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLineManager')->objectIdSearch(
    metaParentId => $obj->getId(),
  );
}
#----------------------------------------------------------------------------
sub getSubOrderLines {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getSubOrderLineIds() );
}
#-----------------------------------------------------------------------------
sub newSubOrderLine {
  my ($obj) = @_;
  return $obj->getManager()->newSubOrderLine($obj);
}
#-----------------------------------------------------------------------------
sub getOrder {
  my ($obj) = @_;
  die "No order ID for order line" unless $obj->getOrderId();
  return $context->getObjectById( $obj->getOrderId() );
}
#-----------------------------------------------------------------------------
# Creating a new Person object based on a Member object
sub setCustomer {
  my ($obj, $customer) = @_;
  return unless $customer;
  
  my $person = $context->getSingleton('O2::Mgr::PersonManager')->newObject();
  foreach my $field (qw(firstName middleName lastName address postalCode postalPlace countryCode phone cellPhone email)) {
    my $getter = 'get' . ucfirst $field;
    my $setter = 'set' . ucfirst $field;
    $person->$setter( $customer->$getter() );
  }
  $person->save();
  $obj->setCustomerId( $person->getId() );
}
#-----------------------------------------------------------------------------
sub getCustomer {
  my ($obj) = @_;
  die 'Customer ID missing for order line ' . $obj->getId() unless $obj->getCustomerId();
  return $context->getObjectById( $obj->getCustomerId() );
}
#-----------------------------------------------------------------------------
sub getCustomerFirstName {
  my ($obj) = @_;
  return $obj->getCustomer()->getFirstName();
}
#--------------------------------------------------------------------------
sub getCustomerMiddleName {
  my ($obj) = @_;
  return $obj->getCustomer()->getMiddleName();
}
#--------------------------------------------------------------------------
sub getCustomerLastName {
  my ($obj) = @_;
  return $obj->getCustomer()->getLastName();
}
#--------------------------------------------------------------------------
sub getCustomerFullName {
  my ($obj) = @_;
  my $name = $obj->getCustomerFirstName();
  $name   .= ' ' . $obj->getCustomerMiddleName() if $obj->getCustomerMiddleName();
  $name   .= ' ' . $obj->getCustomerLastName();
}
#--------------------------------------------------------------------------
sub getCustomerAddress {
  my ($obj) = @_;
  return $obj->getCustomer()->getAddress();
}
#--------------------------------------------------------------------------
sub getCustomerPostalCode {
  my ($obj) = @_;
  return $obj->getCustomer()->getPostalCode();
}
#--------------------------------------------------------------------------
sub getCustomerPostalPlace {
  my ($obj) = @_;
  return $obj->getCustomer()->getPostalPlace() || $obj->getOrder()->getCustomerPostalPlace();
}
#--------------------------------------------------------------------------
sub getCustomerTelephone {
  my ($obj) = @_;
  return $obj->getCustomer()->getPhone() || $obj->getOrder()->getCustomerTelephone();
}
#--------------------------------------------------------------------------
sub getCustomerEmail {
  my ($obj) = @_;
  return $obj->getCustomer()->getEmail();
}
#--------------------------------------------------------------------------
sub getCustomerCellphone {
  my ($obj) = @_;
  return $obj->getCustomer()->getCellPhone();
}
#--------------------------------------------------------------------------
sub getCustomerCountry {
  my ($obj) = @_;
  return $obj->getCustomer()->getCountry();
}
#--------------------------------------------------------------------------
sub getSeller {
  my ($obj) = @_;
  return unless $obj->getSellerId();
  return $context->getObjectById( $obj->getSellerId() );
}
#-----------------------------------------------------------------------------
sub getVatPercentage {
  my ($obj) = @_;
  return $obj->getReceipt()->getVatPercentage() if $obj->getReceiptId();
  return $obj->getProduct()->getVatPercentage();
}
#-----------------------------------------------------------------------------
sub getPriceIncVatExSubOrderLines {
  my ($obj) = @_;
  return $obj->getPriceExVat()  *  (1 + $obj->getVatPercentage()/100) if $obj->getProduct()->getProductType();
  return $obj->getPriceIncVat();
}
#-----------------------------------------------------------------------------
sub getPriceExVatExSubOrderLines {
  my ($obj) = @_;
  return ( $obj->getUnitPriceExVat() - $obj->getUnitDiscountExVat() )  *  $obj->getCount();
}
#-----------------------------------------------------------------------------
sub getPriceIncVatIncSubOrderLines {
  my ($obj) = @_;
  my $total = $obj->getPriceIncVatExSubOrderLines();
  foreach my $orderLine ($obj->getSubOrderLines()) {
    $total += $orderLine->getPriceIncVatIncSubOrderLines();
  }
  return $total;
}
#-----------------------------------------------------------------------------
sub confirmPurchase {
  my ($obj, $status) = @_;
  return unless $obj->_checkStatusBeforeConfirm();
  $context->getSingleton('O2Plugin::Shop::Mgr::ReceiptManager')->createReceipt($obj);
  $obj->setMetaStatus( $status || 'confirmed' );
  $obj->save();
  foreach my $orderLine ($obj->getSubOrderLines()) {
    $orderLine->confirmPurchase($status);
  }
}
#-----------------------------------------------------------------------------
sub _checkStatusBeforeConfirm {
  my ($obj) = @_;
  my $oldStatus = $obj->getMetaStatus();
  return 0 if $oldStatus =~ m{ \A (?: timedOut | trashed | trashedAncestor | deleted ) \z }xms;
  return 1;
}
#-----------------------------------------------------------------------------
sub getUnitPriceIncVat {
  my ($obj) = @_;
  my $product = $obj->getProduct();
  return $obj->getUnitPriceExVat()  *  (1 + $obj->getVatPercentage()/100) if $product->getProductTypeId();
  return $obj->getModelValue('unitPriceIncVat');
}
#----------------------------------------------------------------------------
sub getPriceExVat {
  my ($obj) = @_;
  return $obj->getUnitPriceExVat() * $obj->getCount();
}
#----------------------------------------------------------------------------
sub getPriceIncVat {
  my ($obj) = @_;
  return $obj->getUnitPriceIncVat() * $obj->getCount();
}
#----------------------------------------------------------------------------
sub getProduct {
  my ($obj) = @_;
  my $productId = $obj->getProductId();
  return unless $productId;
  return $context->getObjectById($productId) || $context->getUniversalMgr()->getTrashedObjectById($productId);
}
#-----------------------------------------------------------------------------
sub getReceipt {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getReceiptId() ) if $obj->getReceiptId();
  die 'No receipt has been created';
}
#----------------------------------------------------------------------------
sub getCountPerPriceIncVat {
  my ($obj) = @_;
  return ( $obj->getUnitPriceIncVat() => $obj->getCount() ) unless $obj->can('getReservationPeriods');
  my %prices; # Normally only one price, but not for accomodation. Also useful if other offers were to have various prices in the future.
  foreach my $reservationPeriod ($obj->getReservationPeriods()) {
    $prices{ $reservationPeriod->getUnitPriceIncVat() } += ($reservationPeriod->mustPayPerDay() ? $reservationPeriod->countDays() : 1);
  }
  return %prices;
}
#----------------------------------------------------------------------------
sub getNumUnitsSold {
  my ($obj) = @_;
  return $obj->getCount();
}
#----------------------------------------------------------------------------
sub _getReservationMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLine::ReservationManager');
}
#----------------------------------------------------------------------------
# Setting to a different status depending on whether the order line has been paid for or not.
# If it hasn't been paid for, then we just delete it (status=trashed), otherwise we set
# status to cancelled. Order lines with status=cancelled will appear in Settlement and
# provider statistics.
sub cancel {
  my ($obj) = @_;
  if ($obj->isPaidFor()) {
    $obj->setMetaStatus('cancelled');
    $obj->save();
  }
  else {
    $obj->delete();
  }
}
#----------------------------------------------------------------------------
sub isPaidFor {
  my ($obj) = @_;
  return 1 if $obj->getMetaStatus() eq 'confirmed' || $obj->getMetaStatus() eq 'cancelled';
  return 0;
}
#----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  $obj->getReceipt()->deletePermanently() if $obj->getReceiptId() && $obj->getReceipt();
  if ($obj->getMetaOwnerId()) { # XXX Maybe this block should be customer specific?
    my $customer = $context->getObjectById( $obj->getMetaOwnerId() );
    $customer->deletePermanently() if $customer && ref ($customer) =~ m{ Obj::Person \z }xms;
  }
  my $customer = eval { $obj->getCustomer() }; # Ignore if customer is missing since we're deleting
  $customer->deletePermanently() if $customer && ref ($customer) =~ m{ Obj::Person \z }xms;
  $obj->SUPER::deletePermanently();
}
#----------------------------------------------------------------------------
1;
