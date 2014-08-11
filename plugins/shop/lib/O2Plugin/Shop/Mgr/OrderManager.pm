package O2Plugin::Shop::Mgr::OrderManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $config);
use O2Plugin::Shop::Obj::Order;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Order',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    orderLineIds     => { type => 'O2Plugin::Shop::Obj::OrderLine', listType => 'array'                                        },
    customerId       => { type => 'O2::Obj::Person'                                                                            }, # If the customer is a logged in member, then metaOwnerId will have the same value as this field.
    transactionId    => { type => 'O2Plugin::Shop::Obj::Transaction'                                                           },
    extraInfos       => { type => 'varchar', listType => 'hash'                                                                },
    orderTypeId      => { type => 'O2Plugin::Shop::Obj::OrderType', notNull => 1                                               }, # Would've been nice if we didn't need this
    typeOfSale       => { type => 'varchar', length => '32', defaultValue => 'web', validValues => ['web', 'manual', 'mobile'] },
    confirmationTime => { type => 'epoch'                                                                                      }, # Epoch time of when the order was confirmed (for the first time).
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::Order',
    { name => 'customerIdIndex',    columns => [qw(customerId)],    isUnique => 0 },
    { name => 'transactionIdIndex', columns => [qw(transactionId)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName(ref $object) unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-------------------------------------------------------------------------------
sub getOrderByTransactionId {
  my ($obj, $transactionId) = @_;
  return $obj->objectSearch(
    transactionId => $transactionId,
  );
} 
#-------------------------------------------------------------------------------
sub userIdHasOrders {
  my ($obj, $userId) = @_;
  die "userId missing" unless $userId;
  
  my @orderIds = $obj->objectIdSearch(
    customerId => $userId,
    -limit     => 1,
  );
  return @orderIds > 0;
}
#-------------------------------------------------------------------------------
sub getOrdersByUserId {
  my ($obj, $userId) = @_;
  die "userId missing" unless $userId;
  
  return $obj->objectSearch(
    metaOwnerId => $userId,
    -orderBy    => 'objectId desc',
  );
}
#-------------------------------------------------------------------------------
sub getReservationTimeoutValueInSeconds {
  return $config->get('shop.reservationTimeout');
}
#-------------------------------------------------------------------------------
1;
