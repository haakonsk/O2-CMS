package O2Plugin::Shop::Mgr::OrderLine::ReservationPeriodManager;

use strict;
use base 'O2::Mgr::DatePeriodManager';

use O2Plugin::Shop::Obj::OrderLine::ReservationPeriod;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::OrderLine::ReservationPeriod',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    reservationId  => { type => 'O2Plugin::Shop::Obj::OrderLine::Reservation' },
    unitPriceExVat => { type => 'float'                                       },
    mustPayPerDay  => { type => 'bit'                                         }, # If true, the unit price is multiplied by number of days to get the total price.
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
