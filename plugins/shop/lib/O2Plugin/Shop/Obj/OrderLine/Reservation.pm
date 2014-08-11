package O2Plugin::Shop::Obj::OrderLine::Reservation;

use strict;

use base 'O2Plugin::Shop::Obj::OrderLine';

use O2 qw($context);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub newReservationPeriod {
  my ($obj, %params) = @_;
  my $reservationPeriod = $obj->_getReservationPeriodMgr()->newObject(%params);
  $reservationPeriod->setReservationId( $obj->getId() );
  return $reservationPeriod;
}
#-----------------------------------------------------------------------------
sub addReservationPeriodId {
  my ($obj, $id) = @_;
  my @ids = $obj->getReservationPeriodIds();
  upush @ids, $id;
  $obj->setReservationPeriodIds(@ids);
}
#-----------------------------------------------------------------------------
sub getReservationPeriods {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getReservationPeriodIds() );
}
#-----------------------------------------------------------------------------
sub confirmPurchase {
  my ($obj) = @_;
  return unless $obj->_checkStatusBeforeConfirm();
  
  $obj->SUPER::confirmPurchase();
  $obj->setMetaStatus('confirmed');
  $obj->save();
}
#-----------------------------------------------------------------------------
sub getDurationCount {
  my ($obj) = @_;
  return $obj->countDays();
}
#-----------------------------------------------------------------------------
sub countDays {
  my ($obj) = @_;
  my $count = 0;
  foreach my $reservationPeriod ($obj->getReservationPeriods()) {
    $count += $reservationPeriod->countDays();
  }
  return $count;
}
#-----------------------------------------------------------------------------
sub getPriceExVat {
  my ($obj) = @_;
  my $price;
  foreach my $reservationPeriod ($obj->getReservationPeriods()) {
    $price += $reservationPeriod->getPriceExVat();
  }
  return $price;
#  return $obj->getUnitPriceExVat() * $obj->getCount() * $obj->getDurationCount();
}
#----------------------------------------------------------------------------
sub getPriceIncVat {
  my ($obj) = @_;
  return $obj->getPriceExVat() * (1 + $obj->getVatPercentage()/100);
}
#----------------------------------------------------------------------------
sub getStartDate {
  my ($obj, $format) = @_;
  my $startDate = $obj->getModelValue('startDate');
  return $startDate unless $format;
  return $obj->_formatDate($startDate);
}
#----------------------------------------------------------------------------
sub getEndDate {
  my ($obj, $format) = @_;
  my $endDate = $obj->getModelValue('endDate');
  return $endDate unless $format;
  return $obj->_formatDate($endDate);
}
#----------------------------------------------------------------------------
sub getPriceExVatExSubOrderLines {
  my ($obj) = @_;
  my $price = 0;
  foreach my $reservationPeriod ($obj->getReservationPeriods()) {
    $price += $reservationPeriod->getPriceExVat();
  }
  return $price;
}
#-----------------------------------------------------------------------------
sub getPriceIncVatExSubOrderLines {
  my ($obj) = @_;
  return $obj->getPriceExVatExSubOrderLines() * (1 + $obj->getVatPercentage()/100);
}
#-----------------------------------------------------------------------------
sub getNumUnitsSold {
  my ($obj) = @_;
  return $obj->getCount() * $obj->getDurationCount();
}
#----------------------------------------------------------------------------
sub _formatDate {
  my ($obj, $swedishDate, $format) = @_;
  my $dateFormatter = $context->getDateFormatter();
  my $epoch = $dateFormatter->dateTime2Epoch($swedishDate);
  return $dateFormatter->dateFormat($epoch, $format);
}
#----------------------------------------------------------------------------
sub _getReservationPeriodMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLine::ReservationPeriodManager');
}
#----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $reservationPeriod ($obj->getReservationPeriods()) {
    $reservationPeriod->deletePermanently();
  }
  $obj->SUPER::deletePermanently();
}
#----------------------------------------------------------------------------
1;
