package O2Plugin::Shop::Mgr::PeriodProduct::Calendar::DependencyManager;

use strict;

use base 'O2::Mgr::DatePeriodManager';

use O2Plugin::Shop::Obj::PeriodProduct::Calendar::Dependency;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::PeriodProduct::Calendar::Dependency',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    calendarId => { type => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar' },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::PeriodProduct::Calendar::Dependency',
    { name => 'calendarId_idx', columns => [qw(calendarId)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub setDependency {
  my ($obj, $calendar, $fromDate, $toDate) = @_;
  $obj->clearDependenciesBetweenDates($calendar, $fromDate, $toDate);
  my $dependency = $obj->newObject(
    fromDate => $fromDate,
    toDate   => $toDate,
  );
  $dependency->setMetaName(   'Dependency for calendar ' . $calendar->getId() );
  $dependency->setCalendarId( $calendar->getId()                              );
  $dependency->save();
}
#-----------------------------------------------------------------------------
sub getDependencyAtDate {
  my ($obj, $calendar, $date) = @_;
  return $obj->objectSearch(
    calendarId => $calendar->getId(),
    fromDate   => $date,
    toDate     => $date,
  );
}
#-----------------------------------------------------------------------------
sub clearDependencyAtDate {
  my ($obj, $calendar, $date) = @_;
  $obj->getDependencyAtDate($date)->deletePermanently(); # Or just delete?
}
#-----------------------------------------------------------------------------
sub clearDependenciesBetweenDates {
  my ($obj, $calendar, $fromDate, $toDate) = @_;
  my @dependencies = $obj->objectSearch(
    calendarId => $calendar->getId(),
    fromDate   => { ge => $fromDate },
    toDate     => { le => $toDate   },
  );
  foreach my $dependency (@dependencies) {
    $dependency->deletePermanently(); # Or just delete?
  }
}
#-----------------------------------------------------------------------------
sub getDependencyIdsByCalendar {
  my ($obj, $calendar) = @_;
  return $obj->objectIdSearch(
    calendarId => $calendar->getId(),
  );
}
#-----------------------------------------------------------------------------
1;
