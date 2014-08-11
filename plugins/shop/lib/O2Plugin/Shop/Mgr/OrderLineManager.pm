package O2Plugin::Shop::Mgr::OrderLineManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context);
use O2Plugin::Shop::Obj::OrderLine;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::OrderLine',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    orderId            => { type => 'O2Plugin::Shop::Obj::Order', notNull => 1                            },
    productId          => { type => 'O2Plugin::Shop::Obj::Product', testValueMethod => 'getTestProductId' },
    unitPriceExVat     => { type => 'decimal', length => 10                                               },
    count              => { type => 'int', notNull => 1                                                   },
    receiptId          => { type => 'O2Plugin::Shop::Obj::Receipt'                                        },
    isSent             => { type => 'bit'                                                                 }, # If the product has been sent to the customer
    sellerId           => { type => 'O2::Obj::Member'                                                     }, # Not necessary. sellerId is found through productId.
    extraInfos         => { type => 'varchar', listType => 'hash'                                         },
    unitDiscountExVat  => { type => 'decimal', length => 10                                               }, # For backward compatibility. Maybe not necessary?
    customerId         => { type => 'O2::Obj::Person'                                                     },
    reservationIds     => { type => 'O2Plugin::Shop::Obj::OrderLine::Reservation', listType => 'array'    }, # We have a reservationIds field instead of Reservation inheriting from OrderLine because if the price is different for different dates, we would have to create several order lines if we used inheritance. XXX Move this field to Reservation? Eh.. Do we need this field?
    unitPriceIncVat    => { type => 'float', length => '10'                                               },
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2Plugin::Shop::Obj::OrderLine',
    { name => 'customerIdIndex', columns  => [qw(customerId)], isUnique => 0 },
    { name => 'productIdIndex',  columns  => [qw(productId)],  isUnique => 0 },
    { name => 'orderIdIndex',    columns  => [qw(orderId)],    isUnique => 0 },
  );
}
#-------------------------------------------------------------------------------
sub getOrderLinesByOrderId {
  my ($obj, $orderId) = @_;
  die "Order Id not given" unless $orderId;
  
  my @orderLines = $obj->objectSearch(
    orderId => $orderId,
  );
  return @orderLines;
}
#-------------------------------------------------------------------------------
sub newSubOrderLine {
  my ($obj, $parentOrderLine) = @_;
  my $subOrderLine = $obj->newObject();
  $subOrderLine->setOrderId(      $parentOrderLine->getOrderId()   );
  $subOrderLine->setMetaParentId( $parentOrderLine->getId()        );
  $subOrderLine->setMetaName(     ref $subOrderLine . ' orderline' );
  return $subOrderLine;
}
#-----------------------------------------------------------------------------
sub getTestProductId {
  my ($obj) = @_;
  my $product = $context->getSingleton('O2Plugin::Shop::Mgr::ProductManager')->newObject();
  $product->setMetaName('Test product');
  $product->save();
  
  my $productId = $product->getId();
  push @O2::Script::Test::Common::TEST_OBJECT_IDS, $productId;
  return $productId;
}
#-----------------------------------------------------------------------------
1;
