use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

diag "This test will test the usage of the BBS module's generatePaymentUrl method.";

use O2 qw($context $config);

diag 'Setting up endpointURI and namespace, these should probably be in some config file, but now it must be provided.';
my %params = (
  endpointURI => 'https://epayment-test.bbs.no/Service.svc',
  namespace   => 'http://BBS.EPayment',
);

my ($order, $BBS);

SKIP: {
  skip "No BBS configuration found.", 2 unless $config->get('shop.transaction.bbs');

  diag 'Ok, can we create the BBS object?';
  ok( $BBS = $context->getSingleton('O2Plugin::Shop::Mgr::Transaction::BBSManager')->newObject(%params), 'Successfully created the BBS object, the object is of class: ' . ref $BBS );
  
  my $orderType = [ $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager')->getOrderTypes() ]->[0];
  $order = $orderType->newOrderObject();
  $order->setMetaName( 'Test-order'                                                  );
  $order->setCustomer( $context->getSingleton('O2::Mgr::PersonManager')->newObject() );
  $order->save();
  
  my $result;
  my %params = (
    token               => $config->get('shop.transaction.bbs.token'),
    merchantId          => $config->get('shop.transaction.bbs.merchantId'),
    currency            => $config->get('shop.transaction.bbs.currencyCode'),
    amount              => '100',
    orderNumber         => $order->getId(),
    orderDescription    => 'Test-order',
    customerEmail       => 'fmortens@redpill-linpro.com',
    customerPhoneNumber => '12345678',
    description         => 'This is a test-order',
    returnUrl           => 'http://www.redpill-linpro.com',
    language            => 'en_US',
    sessionId           => '123',
  );

  diag 'Ok, will now try to call the generatePaymentUrl - the desired result here is a URL we can use to pass the user into the BBS system.';

  my $paymentUrl;
  ok( $paymentUrl = $BBS->generatePaymentUrl(%params), "Successfully generated the payment URL, $paymentUrl" );
}

END {
  $order->deletePermanently() if $order;
  $BBS->deletePermanently()   if $BBS;
}
