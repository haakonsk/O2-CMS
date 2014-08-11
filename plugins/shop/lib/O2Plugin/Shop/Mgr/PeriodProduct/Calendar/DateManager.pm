package O2Plugin::Shop::Mgr::PeriodProduct::Calendar::DateManager;

use strict;

use base 'O2::Mgr::DateTimeManager';

use O2Plugin::Shop::Obj::PeriodProduct::Calendar::Date;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::PeriodProduct::Calendar::Date',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    availability => { type => 'bit', defaultValue => '1'                            }, # Available by default
    attributes   => { type => 'varchar', listType => 'array'                        }, # XXX Shouldn't list type be hash here?
    calendarId   => { type => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar'        },
    orderLineIds => { type => 'O2Plugin::Shop::Obj::OrderLine', listType => 'array' }, # Storing orderLineIds here should allow for faster availability checking. XXX Do we need this?
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub getDateObjectByCalendarAndDate {
  my ($obj, $calendar, $swedishDate) = @_;
  my ($date) = $obj->objectSearch(
    calendarId => $calendar->getId(),
    date       => $swedishDate,
  );
  return $date;
}
#-----------------------------------------------------------------------------
sub getAllDateIdsForCalendar {
  my ($obj, $calendar) = @_;
  return $obj->objectIdSearch(
    calendarId => $calendar->getId(),
  );
}
#-----------------------------------------------------------------------------
1;
