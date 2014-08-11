package O2Plugin::Shop::Obj::PeriodProduct;

use strict;

use base 'O2Plugin::Shop::Obj::Product';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  $obj->setMetaName( $obj->getName() ) unless $obj->getMetaName();
  $obj->SUPER::save();
}
#-----------------------------------------------------------------------------
sub getCalendar {
  my ($obj) = @_;
  if ($obj->getCalendarId()) {
    my $calendar = $context->getObjectById( $obj->getCalendarId() );
    return $calendar if $calendar && $calendar->isa('O2Plugin::Shop::Obj::PeriodProduct::Calendar');
    $obj->setCalendarId(undef);
  }
  $obj->save() unless $obj->getId();
  my $calendar = $obj->getCalendarMgr()->newObject();
  $calendar->setMetaName(  'Calendar for product ' . $obj->getId() );
  $calendar->setProductId( $obj->getId()                           );
  $calendar->save();
  $obj->setCalendarId( $calendar->getId() );
  $obj->save();
  return $calendar;
}
#-----------------------------------------------------------------------------
sub getCalendarMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::PeriodProduct::CalendarManager');
}
#-----------------------------------------------------------------------------
sub getValidityPeriods {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getValidityPeriodIds() );
}
#-----------------------------------------------------------------------------
sub getAvailableCountByDate {
  my ($obj, $date) = @_;
  return 0 unless $date->getAvailability();
  return $obj->getManager()->getAvailableCountByProductAndDate($obj, $date);
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj, $object) = @_;
  foreach my $period ($obj->getValidityPeriods()) {
    $period->deletePermanently();
  }
  $obj->getCalendar()->deletePermanently() if $obj->getCalendarId() && $obj->getCalendar();
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
sub getPriceIncVatForDatePeriod {
  my ($obj, $datePeriod) = @_;
  my $totalPrice = 0;
  foreach my $date ($datePeriod->getDates()) {
    $totalPrice += $obj->getPriceIncVatForDate( $obj->getCalendar()->getDate($date) );
  }
  return $totalPrice;
}
#-----------------------------------------------------------------------------
sub getPriceIncVatForDate {
  my ($obj, $date) = @_;
  return $obj->getPriceIncVat();
}
#-----------------------------------------------------------------------------
sub getPriceExVatForDate {
  my ($obj, $date) = @_;
  return $obj->getPriceExVat();
}
#-----------------------------------------------------------------------------
1;
