package O2Plugin::Shop::Mgr::TransactionManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Transaction;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Transaction',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    amount     => { type => 'float', notNull => 1                      },
    currency   => { type => 'varchar', length => 32, notNull => 1      },
    date       => { type => 'int', notNull => 1                        },
    status     => { type => 'varchar', notNull => 1                    }, # XXX Use meta-status?
    orderId    => { type => 'O2Plugin::Shop::Obj::Order', notNull => 1 },
    externalId => { type => 'varchar'                                  },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::Transaction',
    { name => 'orderId_index', columns => [qw(orderId)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $obj->indexForSearch($object, 'o2Shop') if $object->getId();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
sub getTransactionByOrderId {
  my ($obj, $orderId) = @_;
  die "getTransactionByOrderId called without order id" unless $orderId;
  my ($transaction) = $obj->objectSearch(
    orderId => $orderId,
  );
  die "Didn't find transaction for order id $orderId" unless $transaction;
  return $transaction;
}
#-----------------------------------------------------------------------------
sub getTransactionByExternalId {
  my ($obj, $externalId) = @_;
  return $obj->getObjectByExternalId($externalId);
}
#-----------------------------------------------------------------------------
sub getObjectByExternalId {
  my ($obj, $externalId) = @_;
  die "getObjectByExternalId called without external id" unless $externalId;
  my ($transaction) = $obj->objectSearch(
    externalId => $externalId,
  );
  die "Didn't find transaction for external id $externalId" unless $transaction;
  return $transaction;
}
#-----------------------------------------------------------------------------
sub getReservedTransactions {
  my ($obj, $fromDate, $toDate) = @_;
  return $obj->objectSearch(
    status => 'reserved',
    date   => {
      ge => $fromDate || '19000101',
      le => $toDate   || '99991231',
    },
  );
}
#-----------------------------------------------------------------------------
1;
