package O2Plugin::Shop::Obj::PeriodProduct::Calendar;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub getDate {
  my ($obj, $swedishDate) = @_;
  my $date = $obj->getDateMgr()->getDateObjectByCalendarAndDate($obj, $swedishDate);
  return $date if $date;
  
  $date = $obj->getDateMgr()->newObject();
  $date->setDateTime($swedishDate);
  $obj->save() unless $obj->getId();
  $date->setCalendarId( $obj->getId() );
  return $date;
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getProduct {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getProductId() );
}
#-----------------------------------------------------------------------------
sub setDependency {
  my ($obj, $fromDate, $toDate) = @_;
  return $obj->getDependencyMgr()->setDependency($obj, $fromDate, $toDate);
}
#-----------------------------------------------------------------------------
# If there used to be a dependency at this date, then delete the dependency.
# Returns the last date that was deleted.
sub clearDependency {
  my ($obj, $date) = @_;
  return $obj->getDependencyMgr()->clearDependencyAtDate($obj, $date);
}
#-----------------------------------------------------------------------------
sub getDateMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::PeriodProduct::Calendar::DateManager');
}
#-----------------------------------------------------------------------------
sub getDateIds {
  my ($obj) = @_;
  return $obj->getDateMgr()->getAllDateIdsForCalendar($obj);
}
#-----------------------------------------------------------------------------
sub getDates {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getDateIds() );
}
#-----------------------------------------------------------------------------
sub getDependencyMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::PeriodProduct::Calendar::DependencyManager');
}
#-----------------------------------------------------------------------------
sub getDependencyIds {
  my ($obj) = @_;
  return $obj->getDependencyMgr()->getDependencyIdsByCalendar($obj);
}
#-----------------------------------------------------------------------------
sub getDependencies {
  my ($obj) = @_;
  return $context->getObjectsByIds( $obj->getDependencyIds() );
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $date ($obj->getDates()) {
    $date->deletePermanently();
  }
  foreach my $dependency ($obj->getDependencies()) {
    $dependency->deletePermanently();
  }
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
1;
