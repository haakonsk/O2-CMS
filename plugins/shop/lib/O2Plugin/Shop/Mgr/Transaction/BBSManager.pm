package O2Plugin::Shop::Mgr::Transaction::BBSManager;

use strict;

use base 'O2Plugin::Shop::Mgr::TransactionManager';

use O2Plugin::Shop::Obj::Transaction::BBS;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Transaction::BBS',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
