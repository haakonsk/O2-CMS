# Building a product, then buying it.

use Test::More qw(no_plan);

use O2 qw($context $config);
use O2::Script::Test::Common;
use O2::Script::Common;

my $todayEpoch = time;

$context->getSingleton('O2::File')->writeFile( $config->get('setup.tmpDir') . '/createdObjects.txt', '' );

diag "Create some product variants";
my $productVariantMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Product::VariantManager');
my $productVariant1 = $productVariantMgr->newObject();
my $productVariant2 = $productVariantMgr->newObject();
foreach my $locale ($productVariant1->getAvailableLocales()) {
  $productVariant1->setName( $locale eq 'nb_NO' ? 'Farge'  : 'Color'  );
  $productVariant2->setName( $locale eq 'nb_NO' ? 'Høyde'  : 'Height' );
  $productVariant2->setUnit('m');
  $productVariant1->setDefaultValue( $locale eq 'nb_NO' ? 'Rød' : 'Red' );
  $productVariant2->setDefaultValue(2.0);
}
$productVariant2->setValueType('float');
$productVariant1->save();
$productVariant2->save();

diag "Create a new product type";
my $productType = $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->newObject();
foreach my $locale ($productType->getAvailableLocales()) {
  $productType->setName("TheProductType $locale");
}
$productType->setVatPercentage( 25                                                   );
$productType->setVariantIds(    $productVariant1->getId(), $productVariant2->getId() );
#$productType->setAvailabilityManagerClassName( 'O2Plugin::Shop::Mgr::Product::PeriodProduct::AvailabilityManager' ); # Maybe not necessary: PeriodProduct can have a default availabilityMgr.
$productType->save();

diag "Create options for the product variants";
my $productVariantOption1 = $productVariant1->newProductVariantOption();
my $productVariantOption2 = $productVariant2->newProductVariantOption();
foreach my $locale ($productVariantOption1->getAvailableLocales()) {
  $productVariantOption1->setValue( $locale eq 'nb_NO' ? 'Blå' : 'Blue' );
  $productVariantOption2->setValue( 3.5                                 );
}
$productVariantOption1->setPriceModifierExVat( '+2'  );
$productVariantOption2->setPriceModifierExVat( '+10' );
$productVariantOption1->save();
$productVariantOption2->save();

diag "Create the periods when the product should be valid";
my $datePeriodMgr = $context->getSingleton('O2::Mgr::DatePeriodManager');
my $dateTimeMgr   = $context->getSingleton('O2::Mgr::DateTimeManager');
my $period1 = $datePeriodMgr->newObject(
  fromDate => $dateTimeMgr->newObject($todayEpoch +  7*24*60*60),
  toDate   => $dateTimeMgr->newObject($todayEpoch +  9*24*60*60),
);
my $period2 = $datePeriodMgr->newObject(
  fromDate => $dateTimeMgr->newObject($todayEpoch + 12*24*60*60),
  toDate   => $dateTimeMgr->newObject($todayEpoch + 17*24*60*60),
);
$period1->save();
$period2->save();

diag "Create a new period product";
my $product = $context->getSingleton('O2Plugin::Shop::Mgr::PeriodProductManager')->newObject();
foreach my $locale ($product->getAvailableLocales()) {
  $product->setCurrentLocale($locale);
  $product->setName(        "PeriodProductTest $locale"         );
  $product->setSummary(     'This is the summary. Blah blah...' );
  $product->setDescription( 'The description goes here..'       );
}
$product->setProductTypeId(     $productType->getId() );
$product->setProductId(         'abc123'              );
$product->setDefaultPriceExVat( 100                   );
$product->setIsActive(1);
$product->setVariantOptionIds( $productVariantOption1->getId(), $productVariantOption2->getId() );
$product->setValidityPeriodIds( $period1->getId(), $period2->getId() );
my $calendar = $product->getCalendar();
my $dateInfo = $calendar->getDate( day(7) );
$dateInfo->setAvailability(1);
$dateInfo->setAttribute('seasonType', 'high');
$dateInfo->setAttribute('comment', 'En kommentar');
$dateInfo->save();
$calendar->setDependency( day(8), day(9) );
$product->save(); # Save calendar and dates as well?

diag "Now that we finally have a valid product, we can create an order";
my $orderType = $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager')->newObject();
$orderType->setMetaName(       'Test-order-type'            );
$orderType->setOrderClassName( 'O2Plugin::Shop::Obj::Order' );
$orderType->setReceiptTemplatesDirectory( '.' );
$orderType->setOrderTemplatesDirectory(   '.' );
$orderType->save();
my $order = $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->newObject();
$order->setOrderTypeId( $orderType->getId() );
my $reservation = $order->addReservation(
  $product,
  fromEpoch     => $todayEpoch + 13*24*60*60,
  toEpoch       => $todayEpoch + 15*24*60*60,
  mustPayPerDay => 1,
  # Other available params: fromDate, toDate, date, epoch
);

$order->save();
is( $order->getPriceExVat(), (100+2+10)*3, 'Price is correct' );

my $personMgr = $context->getSingleton('O2::Mgr::PersonManager');
my $person = $personMgr->newObject();
$person->setFirstName(   'Håkon'                       );
$person->setMiddleName(  'Skaarud'                     );
$person->setLastName(    'Karlsen'                     );
$person->setBirthDate(   '19790105'                    );
$person->setEmail(       'haakonsk@redpill-linpro.com' );
$person->setAddress(     'Rasmus Winderens vei 31'     );
$person->setPostalCode(  '0373'                        );
$person->setPostalPlace( 'Oslo'                        );
$person->setCellPhone(   '98632441'                    );
$person->setCountryCode( 'no'                          );
$person->setAttribute(   'huntNumber', 123             );
$person->save();
$order->setCustomerId( $person->getId() );

my $i = 0;
foreach my $reservation ($order->getOrderLines()) {
  $i++;
  my $person = $personMgr->newObject();
  $person->setFirstName(   "Håkon $i"                           );
  $person->setMiddleName(  "Skaarud $i"                         );
  $person->setLastName(    "Karlsen $i"                         );
  $person->setBirthDate(   "19790105 $i"                        );
  $person->setEmail(       "haakonsk\@redpill-linpro.com.no $i" );
  $person->setAddress(     "Rasmus Winderens vei 31 $i"         );
  $person->setPostalCode(  "0373"                               );
  $person->setPostalPlace( "Oslo $i"                            );
  $person->setCellPhone(   "98632441 $i"                        );
  $person->setCountryCode( 'no'                                 );
  $person->setAttribute(   'huntNumber', "123 $i"               );
  $person->save();
  $reservation->setCustomerId( $person->getId() );
  $reservation->save();
}

$order->save();

diag "Pay for the order";
my $transaction;
eval {
  $transaction = $order->getTransaction(); # Creates a new transaction object (and saves it?) if none exists. The transaction type should come from a config or something.
};
if ($@) {
  diag "Not able to test payment";
  exit;
}
my $paymentUrl = $transaction->generatePaymentUrl(
  returnUrl => 'http://www.redpill-linpro.com',
);

# Returns the date of the day that is $dayNum days from now
sub day {
  my ($dayNum) = @_;
  return $context->getDateFormatter()->dateFormat( time + $dayNum*24*60*60, 'yyyyMMdd' );
}

END {
  $productVariant1->deletePermanently() if $productVariant1;
  $productVariant2->deletePermanently() if $productVariant2;
  $productType->deletePermanently()     if $productType;
  $product->deletePermanently()         if $product; # Responsible for deleting it's variant options and it's periods
  $transaction->deletePermanently()     if $transaction;
  $order->deletePermanently()           if $order; # Deletes order lines, persons and receipts as well
  $orderType->deletePermanently()       if $orderType;
}
