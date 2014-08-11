package O2Plugin::Shop::Mgr::PeriodProduct::CalendarManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::PeriodProduct::Calendar;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::PeriodProduct::Calendar',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    productId => { type => 'O2Plugin::Shop::Obj::PeriodProduct' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
