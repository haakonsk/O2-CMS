package O2Plugin::Shop::Obj::PeriodProduct::Calendar::Dependency;

use strict;

use base 'O2::Obj::DatePeriod';

#-----------------------------------------------------------------------------
sub containsDate {
  my ($obj, $date) = @_;
  return $date ge $obj->getFromDate() && $date le $obj->getToDate();
}
#-----------------------------------------------------------------------------
1;
