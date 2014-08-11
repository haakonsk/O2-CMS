package O2Plugin::Shop::Mgr::Transaction::PayPalManager;

use strict;

use base 'O2Plugin::Shop::Mgr::TransactionManager';

use O2Plugin::Shop::Obj::Transaction::PayPal;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Transaction::PayPal',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub newObject {
  die "This is an abstract class";
}
#-------------------------------------------------------------------------------
sub init {
  die "This is an abstract class";
}
#-------------------------------------------------------------------------------
sub save {
  die "This is an abstract class";
}
#-------------------------------------------------------------------------------
1;
