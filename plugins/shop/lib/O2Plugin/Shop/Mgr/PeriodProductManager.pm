package O2Plugin::Shop::Mgr::PeriodProductManager;

use strict;

use base 'O2Plugin::Shop::Mgr::ProductManager';

use O2 qw($context);
use O2Plugin::Shop::Obj::PeriodProduct;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::PeriodProduct',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    validityPeriodIds => { type => 'O2::Obj::DatePeriod', listType => 'array'     },
    calendarId        => { type => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub getAvailableCountByProductAndDate {
  my ($obj, $product, $date) = @_;
  my $numReservations = $context->getSingleton('O2Plugin::Shop::Mgr::OrderLine::ReservationManager')->countValidReservationsByProductIdAndDate( $product->getId(), $date );
  return  $numReservations == 0  ?  1  :  0;
}
#-----------------------------------------------------------------------------
1;
