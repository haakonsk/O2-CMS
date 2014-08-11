use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

my %tableNames = (
  'O2_OBJ_SHOP_ORDER'                             => 'O2PLUGIN_SHOP_OBJ_ORDER',
  'O2_OBJ_SHOP_ORDERLINE'                         => 'O2PLUGIN_SHOP_OBJ_ORDERLINE',
  'O2_OBJ_SHOP_ORDERLINE_RESERVATION'             => 'O2PLUGIN_SHOP_OBJ_ORDERLINE_RESERVATION',
  'O2_OBJ_SHOP_ORDERLINE_RESERVATIONPERIOD'       => 'O2PLUGIN_SHOP_OBJ_ORDERLINE_RESERVATIONPERIOD',
  'O2_OBJ_SHOP_ORDERTYPE'                         => 'O2PLUGIN_SHOP_OBJ_ORDERTYPE',
  'O2_OBJ_SHOP_TRANSACTION'                       => 'O2PLUGIN_SHOP_OBJ_TRANSACTION',
  'O2_OBJ_SHOP_TRANSACTION_BBS'                   => 'O2PLUGIN_SHOP_OBJ_TRANSACTION_BBS',
  'O2_OBJ_SHOP_TRANSACTION_PAYPAL'                => 'O2PLUGIN_SHOP_OBJ_TRANSACTION_PAYPAL',
  'O2_OBJ_SHOP_TRANSACTION_PAYPAL_DIRECT'         => 'O2PLUGIN_SHOP_OBJ_TRANSACTION_PAYPAL_DIRECT',
  'O2_OBJ_SHOP_TRANSACTION_PAYPAL_EXPRESS'        => 'O2PLUGIN_SHOP_OBJ_TRANSACTION_PAYPAL_EXPRESS',
  'O2_OBJ_SHOP_TRANSACTION_LOG'                   => 'O2PLUGIN_SHOP_OBJ_TRANSACTION_LOG',
  'O2_OBJ_SHOP_PERIODPRODUCT'                     => 'O2PLUGIN_SHOP_OBJ_PERIODPRODUCT',
  'O2_OBJ_SHOP_PERIODPRODUCT_CALENDAR'            => 'O2PLUGIN_SHOP_OBJ_PERIODPRODUCT_CALENDAR',
  'O2_OBJ_SHOP_PERIODPRODUCT_CALENDAR_DATE'       => 'O2PLUGIN_SHOP_OBJ_PERIODPRODUCT_CALENDAR_DATE',
  'O2_OBJ_SHOP_PERIODPRODUCT_CALENDAR_DEPENDENCY' => 'O2PLUGIN_SHOP_OBJ_PERIODPRODUCT_CALENDAR_DEPENDENCY',
  'O2_OBJ_SHOP_PRODUCT'                           => 'O2PLUGIN_SHOP_OBJ_PRODUCT',
  'O2_OBJ_SHOP_PRODUCTTYPE'                       => 'O2PLUGIN_SHOP_OBJ_PRODUCTTYPE',
  'O2_OBJ_SHOP_PRODUCT_CATEGORY'                  => 'O2PLUGIN_SHOP_OBJ_PRODUCT_CATEGORY',
  'O2_OBJ_SHOP_PRODUCT_VARIANT'                   => 'O2PLUGIN_SHOP_OBJ_PRODUCT_VARIANT',
  'O2_OBJ_SHOP_PRODUCT_VARIANT_OPTION'            => 'O2PLUGIN_SHOP_OBJ_PRODUCT_VARIANT_OPTION',
  'O2_OBJ_SHOP_CART'                              => 'O2PLUGIN_SHOP_OBJ_CART',
  'O2_OBJ_SHOP_CART_ITEM'                         => 'O2PLUGIN_SHOP_OBJ_CART_ITEM',
  'O2_OBJ_SHOP_RECEIPT'                           => 'O2PLUGIN_SHOP_OBJ_RECEIPT',
);

my %classNames = (
  'O2::Obj::Shop::Order'                               => 'O2Plugin::Shop::Obj::Order',
  'O2::Obj::Shop::OrderLine'                           => 'O2Plugin::Shop::Obj::OrderLine',
  'O2::Obj::Shop::OrderLine::Reservation'              => 'O2Plugin::Shop::Obj::OrderLine::Reservation',
  'O2::Obj::Shop::OrderLine::ReservationPeriod'        => 'O2Plugin::Shop::Obj::OrderLine::ReservationPeriod',
  'O2::Obj::Shop::OrderType'                           => 'O2Plugin::Shop::Obj::OrderType',
  'O2::Obj::Shop::Transaction'                         => 'O2Plugin::Shop::Obj::Transaction',
  'O2::Obj::Shop::Transaction::BBS'                    => 'O2Plugin::Shop::Obj::Transaction::BBS',
  'O2::Obj::Shop::Transaction::PayPal'                 => 'O2Plugin::Shop::Obj::Transaction::PayPal',
  'O2::Obj::Shop::Transaction::PayPal::Direct'         => 'O2Plugin::Shop::Obj::Transaction::PayPal::Direct',
  'O2::Obj::Shop::Transaction::PayPal::Express'        => 'O2Plugin::Shop::Obj::Transaction::PayPal::Express',
  'O2::Obj::Shop::PeriodProduct'                       => 'O2Plugin::Shop::Obj::PeriodProduct',
  'O2::Obj::Shop::PeriodProduct::Calendar'             => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar',
  'O2::Obj::Shop::PeriodProduct::Calendar::Date'       => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar::Date',
  'O2::Obj::Shop::PeriodProduct::Calendar::Dependency' => 'O2Plugin::Shop::Obj::PeriodProduct::Calendar::Dependency',
  'O2::Obj::Shop::Product'                             => 'O2Plugin::Shop::Obj::Product',
  'O2::Obj::Shop::ProductType'                         => 'O2Plugin::Shop::Obj::ProductType',
  'O2::Obj::Shop::Product::Category'                   => 'O2Plugin::Shop::Obj::Product::Category',
  'O2::Obj::Shop::Product::Variant'                    => 'O2Plugin::Shop::Obj::Product::Variant',
  'O2::Obj::Shop::Product::Variant::Option'            => 'O2Plugin::Shop::Obj::Product::Variant::Option',
  'O2::Obj::Shop::Cart'                                => 'O2Plugin::Shop::Obj::Cart',
  'O2::Obj::Shop::Cart::Item'                          => 'O2Plugin::Shop::Obj::Cart::Item',
  'O2::Obj::Shop::Receipt'                             => 'O2Plugin::Shop::Obj::Receipt',
);

use O2::Context;
my $context = O2::Context->new();
my $dbh     = $context->getDbh();

my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');
my $dbIntrospect = $context->getSingleton('O2::DB::Util::Introspect');

warn "Going through tables";
while (my ($tableName, $newTableName) = each %tableNames) {
  if ($dbIntrospect->tableExists($tableName)) {
    $schemaMgr->renameTable($tableName, $newTableName);
  }
}

warn "Going through classes";
while (my ($className, $newClassName) = each %classNames) {
  $dbh->sql("update O2_OBJ_OBJECT set className = ? where className = ?", $newClassName, $className);
}

warn "Renaming classes for field usableClasses in O2Plugin::Obj::Template::Object";
while (my ($class, $newClass) = each %classNames) {
  $dbh->sql("update O2_OBJ_OBJECT_VARCHAR set value = ? where name like 'usableClasses.0%' and value = ?", $newClass, $class);
}

warn "Updating orderClassName in O2Plugin::Shop::Obj::OrderType";
while (my ($class, $newClass) = each %classNames) {
  warn $newClass;
  my @rows = $dbh->fetchAll("select objectId, orderClassName from O2PLUGIN_SHOP_OBJ_ORDERTYPE where orderClassName = ?", $class);
  foreach my $row (@rows) {
    warn "$class => $newClass";
    $dbh->do( "update O2PLUGIN_SHOP_OBJ_ORDERTYPE set orderClassName = ? where objectId = ?", $newClass, $row->{objectId} );
  }
}

my $cacher = $context->getMemcached();
if (!$cacher->isa('O2::Cache::Dummy')) {
  warn "Deleting from cache";
  my @ids = $dbh->selectColumn("select objectId from O2_OBJ_OBJECT where className like 'O2Plugin::%'");
  foreach my $id (@ids) {
    $cacher->deleteObjectById($id);
  }
}
