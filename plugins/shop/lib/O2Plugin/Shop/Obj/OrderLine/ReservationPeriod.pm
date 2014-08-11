package O2Plugin::Shop::Obj::OrderLine::ReservationPeriod;

use strict;

use base 'O2::Obj::DatePeriod';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub setUnitPriceIncVat {
  my ($obj, $priceIncVat) = @_;
  my $priceExVat = $priceIncVat  /  (1 + $obj->getVatPercentage()/100);
  $obj->setUnitPriceExVat($priceExVat);
}
#-----------------------------------------------------------------------------
sub getUnitPriceIncVat {
  my ($obj) = @_;
  return $obj->getUnitPriceExVat() * (1 + $obj->getVatPercentage()/100);
}
#-----------------------------------------------------------------------------
sub getVatPercentage {
  my ($obj) = @_;
  return $obj->getReservation()->getVatPercentage();
}
#-----------------------------------------------------------------------------
sub getReservation {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getReservationId() );
}
#-----------------------------------------------------------------------------
sub mustPayPerDay {
  my ($obj) = @_;
  return $obj->getMustPayPerDay();
}
#-----------------------------------------------------------------------------
sub getPriceExVat {
  my ($obj) = @_;
  return $obj->getUnitPriceExVat() * $obj->getTotalNumDates() if $obj->mustPayPerDay();
  return $obj->getUnitPriceExVat();
}
#-----------------------------------------------------------------------------
1;
