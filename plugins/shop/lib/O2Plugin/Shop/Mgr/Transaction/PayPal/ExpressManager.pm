package O2Plugin::Shop::Mgr::Transaction::PayPal::ExpressManager;

use strict;

use base 'O2Plugin::Shop::Mgr::TransactionManager';

use O2Plugin::Shop::Obj::Transaction::PayPal::Express;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Transaction::PayPal::Express',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
