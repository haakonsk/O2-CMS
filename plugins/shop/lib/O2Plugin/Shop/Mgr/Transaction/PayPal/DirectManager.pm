package O2Plugin::Shop::Mgr::Transaction::PayPal::DirectManager;

use strict;

use base 'O2Plugin::Shop::Mgr::TransactionManager';

use O2Plugin::Shop::Obj::Transaction::PayPal::Direct;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Transaction::PayPal::Direct',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
