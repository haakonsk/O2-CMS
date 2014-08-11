package O2Plugin::Shop::Mgr::OrderTypeManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::OrderType;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::OrderType',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    orderClassName            => { type => 'varchar' },
    orderGuiClassName         => { type => 'varchar' },
    orderTemplatesDirectory   => { type => 'varchar' },
    receiptGuiClassName       => { type => 'varchar' },
    receiptTemplatesDirectory => { type => 'varchar' },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getAvailableStatusesAsHash {
  my ($obj) = @_;
  return (
    created                => 'Created',
    cancelled              => 'Cancelled',
    timedOut               => 'Timed out',
    confirmed              => 'Confirmed',
    failedToReceivePayment => 'Failed to receive payment',
  );
}
#-------------------------------------------------------------------------------
sub getOrderTypes {
  my ($obj) = @_;
  return $obj->objectSearch();
}
#-------------------------------------------------------------------------------
1;
