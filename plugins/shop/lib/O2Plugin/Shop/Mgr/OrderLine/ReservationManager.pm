package O2Plugin::Shop::Mgr::OrderLine::ReservationManager;

use strict;

use base 'O2Plugin::Shop::Mgr::OrderLineManager';

use O2 qw($context);
use O2Plugin::Shop::Obj::OrderLine::Reservation;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::OrderLine::Reservation',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    reservationPeriodIds => { type => 'O2Plugin::Shop::Obj::OrderLine::ReservationPeriod', listType => 'array' }, # Because the price may change from day to day, it may be necessary to divide a reservation up into several reservation periods.
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub countValidReservationsByProductId {
  my ($obj, $productId) = @_;
  my $product = $context->getObjectById($productId);
  return $obj->countValidReservationsByProductIdAndPeriod($productId, $product->getFirstDate(), $product->getLastDate());
}
#-----------------------------------------------------------------------------
sub countValidReservationsByProductIdAndDate {
  my ($obj, $productId, $date) = @_;
  my $swedishDate = $date->format('yyyyMMdd');
  return $obj->countValidReservationsByProductIdAndPeriod($productId, $swedishDate, $swedishDate);
}
#-----------------------------------------------------------------------------
sub countValidReservationsByProductIdAndPeriod {
  my ($obj, $productId, $fromDate, $toDate) = @_;
  return $obj->{numValidReservations}->{"$productId-$fromDate-$toDate"} if defined $obj->{numValidReservations}->{"$productId-$fromDate-$toDate"}; # Cache for current request
  my @reservationIds = $obj->objectIdSearch(
    productId  => $productId,
    metaStatus => { in => [ qw(confirmed reserved) ] },
  );
  @reservationIds = $obj->objectIdSearch(
    objectId                          => { in => \@reservationIds },
    'reservationPeriodIds->startDate' => { le => $toDate          },
    'reservationPeriodIds->endDate'   => { ge => $fromDate        },
  );
  my $count = scalar @reservationIds;
  return $obj->{numValidReservations}->{"$productId-$fromDate-$toDate"} = $count;
}
#-----------------------------------------------------------------------------
sub timeoutOldReservationsByProductId {
  my ($obj, $productId) = @_;
  my @oldReservations = $obj->objectSearch(
    productId      => $productId,
    metaStatus     => 'reserved',
    metaChangeTime => { lt => time - $obj->getReservationTimeoutValueInSeconds() },
  );

  foreach my $reservation (@oldReservations) {
    $reservation->setMetaStatus('timedOut');
    $reservation->save();
  }
}
#-----------------------------------------------------------------------------
sub getReservationTimeoutValueInSeconds {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->getReservationTimeoutValueInSeconds();
}
#-----------------------------------------------------------------------------
1;
