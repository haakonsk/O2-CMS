use strict;
#---------------------------------------------------------------------------------------------- Dependencies
use Test::More qw(no_plan);
use O2::Context;
use O2::Script::Test::Common;
#------------------------------------------------------------------------------------------ Dependency tests
diag "\nFunction test for O2Plugin::Shop::Obj::Cart\n";
use_ok( 'O2Plugin::Shop::Obj::Cart' );
use_ok( 'O2Plugin::Shop::Mgr::CartManager' );
#----------------------------------------------------------------------------------------------- Create test
my $context = O2::Context->new();
my $cart = $context->getSingleton('O2Plugin::Shop::Mgr::CartManager')->newObject();
isa_ok( $cart => 'O2Plugin::Shop::Obj::Cart' );
#----------------------------------------------------------------------------------- create initial products
diag "\nAdding some products to use in cart\n";
use_ok( 'O2Plugin::Shop::Obj::Product' );
use_ok( 'O2Plugin::Shop::Mgr::ProductManager' );
#-----------------------------------------------------------------------------------------------------------
diag "\nHandling variant options for product\n";
use O2Plugin::Shop::Mgr::Product::VariantManager;
my $variantMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Product::VariantManager');
my $variant    = $variantMgr->newObject();
isa_ok( $variant => 'O2Plugin::Shop::Obj::Product::Variant' );

$variant->setMetaName('Power output');
$variant->setName('Power output');
$variant->setDescription("Power output of weapon");
$variant->setUnit("Gigajoules");
$variant->save();

diag "\nAssigning options to variant\n";
use O2Plugin::Shop::Mgr::Product::Variant::OptionManager;
my $optionMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Product::Variant::OptionManager');

my $option1 = $optionMgr->newObject();
my $option2 = $optionMgr->newObject();

isa_ok( $option1 => 'O2Plugin::Shop::Obj::Product::Variant::Option');
isa_ok( $option2 => 'O2Plugin::Shop::Obj::Product::Variant::Option');

diag "\nFilling up options with data\n";
$option1->setMetaName( 'Energy output' );
$option2->setMetaName( 'Energy output' );
$option1->setValue( '1000' );
$option2->setValue( '2000' );
$option1->setPriceModifierExVat( '+10' );
$option2->setPriceModifierExVat( '-5'  );
$option1->save();
$option2->save();

diag "\nAdding options to variant\n";
$variant->setOptionIds( $option1->getId(), $option2->getId() );
$variant->save();
#-----------------------------------------------------------------------------------------------------------
diag "\nCreating product type\n";
my $productType = $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->newObject();
$productType->setMetaName(      'Test-product-type' );
$productType->setVatPercentage( 25                  );
$productType->setVariantIds(    $variant->getId()   );
$productType->save();
#-----------------------------------------------------------------------------------------------------------
my $productMgr = $context->getSingleton('O2Plugin::Shop::Mgr::ProductManager');
#-----------------------------------------------------------------------------------------------------------
diag "\nCreating product1\n";
my $product1 = $productMgr->newObject();
isa_ok( $product1 => 'O2Plugin::Shop::Obj::Product' );
ok( $product1->setMetaName( 'Product' ), 'assigned metaName Product to product1' );
ok( $product1->setName( 'BFG 9000' ), 'assigned name to product1' );
ok( $product1->setIsActive( 1 ), 'assigned active to 1' );
ok( $product1->setProductTypeId( $productType->getId() ), 'assigned product type to product1' );
ok( $product1->setDefaultPriceIncVat( 57.50 ), 'assigned priceIncVat to product1' );
ok( $product1->setDefaultPriceExVat( 30.75 ), 'assigned priceExVat to product1' );
diag "\nStoring product1\n";
$product1->save();
diag "ObjectId: ".$product1->getId()."\n";
#-----------------------------------------------------------------------------------------------------------
diag "\nCreating product2\n";
my $product2 = $productMgr->newObject();
isa_ok( $product2 => 'O2Plugin::Shop::Obj::Product' );
ok( $product2->setMetaName( 'Product' ), 'assigned metaName Product to product2' );
ok( $product2->setName( 'Marsec 4000' ), 'assigned name to product2' );
ok( $product2->setIsActive( 1 ), 'assigned active to 1' );
ok( $product2->setProductTypeId( $productType->getId() ), 'assigned product type to product2' );
ok( $product2->setDefaultPriceIncVat( 200.15 ), 'assigned priceIncVat to product2' );
ok( $product2->setDefaultPriceExVat( 150.10 ), 'assigned priceExVat to product2' );
diag "\nStoring product2\n";
$product2->save();
diag "ObjectId: ".$product2->getId()."\n";
#-----------------------------------------------------------------------------------------------------------
diag "\nWriting data to object\n";
ok( $cart->setMetaName( 'Cart' ), 'assigned metaName Cart to object' );
ok( $cart->setMetaOwnerId( 347247 ), 'assigned metaOwnerId to object' );
#-----------------------------------------------------------------------------------------------------------
diag "\nSelecting product and variant and placing it into item\n";
use_ok( 'O2Plugin::Shop::Mgr::Cart::ItemManager' );
my $itemMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Cart::ItemManager');

my $item = $itemMgr->newObject();
isa_ok( $item => 'O2Plugin::Shop::Obj::Cart::Item' );
ok( $item->setMetaName( 'cartItem' ), 'successfully assigned metaName to item' );
ok( $item->setProductId( $product1->getId() ), 'successfully assigned productId to item' );
ok( $item->setAmount( 1 ), 'successfully assigned amount to item' );
ok( $item->setVariantOptionIds( $variant->getId() => $option1->getId() ), 'successfully assinged variant option to item');
$item->save();

my $item2 = $itemMgr->newObject();
isa_ok( $item2 => 'O2Plugin::Shop::Obj::Cart::Item' );
ok( $item2->setMetaName( 'cartItem2' ), 'successfully assigned metaName to item' );
ok( $item2->setProductId( $product2->getId() ), 'successfully assigned productId to item' );
ok( $item2->setAmount( 1 ), 'successfully assigned amount to item' );
ok( $item2->setVariantOptionIds( $variant->getId() => $option2->getId() ), 'successfully assinged variant option to item2');
$item2->save();

diag "\nConnecting item to cart\n";
ok( $cart->setItemIds( $item->getId() ), 'successfully placed item into cart' );
$cart->save();
#-----------------------------------------------------------------------------------------------------------
diag "\nFunction test on cart\n";

ok( $cart->updateAmount( $item->getId(), 4), 'successfully updated amount in cart' );
ok( $cart->removeItem( $item->getId() ), 'successfully removed item from cart' );

my %variantOptionIds = ();
$variantOptionIds{ $variant->getId() } = $option1->getId();

diag "\nAdding a product to cart\n";
ok( $cart->addItem( $product2->getId(), 2, \%variantOptionIds ), 'successfully added a product to cart' );

my %variantOptionIds;
$variantOptionIds{ $variant->getId() } = $option2->getId();

diag "\nAdding another product to cart\n";
ok( $cart->addItem( $product1->getId(), 4, \%variantOptionIds ), 'successfully added a product to cart' );


diag "Products in cart:\t" . $cart->countProducts()  . "\n";
diag "Total inc Vat:\t\t"  . $cart->getTotalIncVat() . "\n";
diag "Total ex Vat:\t\t"   . $cart->getTotalExVat()  . "\n";

#--------------------------------------------------------------------------------------------------- Example
diag "\nDisplay content of shopping cart:\n";

my @itemIdsCart = $cart->getItemIds();

foreach my $itemId (@itemIdsCart) {
  my $itemInCart = $itemMgr->getObjectById($itemId);
  diag $itemInCart->getAmount() . ' x ';
  my $productInItem = $productMgr->getObjectById( $itemInCart->getProductId() );
  diag $productInItem->getName() . ', ';
  
  my %variantOptionIds = $itemInCart->getVariantOptionIds();
  
  foreach my $variantId ( keys %variantOptionIds ) {
    my $variantInItem = $variantMgr->getObjectById($variantId);
    my $variantOption = $optionMgr->getObjectById( $variantOptionIds{$variantId} );
    diag $variantOption->getValue() . ' ' . $variantInItem->getUnit() . ', ';
  }
   
  diag $productInItem->getPriceIncVat();
  diag "\n";
}

diag 'Total: ' . $cart->getTotalIncVat() . "\n";

$cart->clear();
#--------------------------------------------------------------------------------------------------- cleanup
diag "\nTest complete, cleaning up...\n";
END {
  $cart->deletePermanently()        if $cart;
  $product1->deletePermanently()    if $product1;
  $product2->deletePermanently()    if $product2;
  $variant->deletePermanently()     if $variant;
  $option1->deletePermanently()     if $option1;
  $option2->deletePermanently()     if $option2;
  $item->deletePermanently()        if $item;
  $item2->deletePermanently()       if $item2;
  $productType->deletePermanently() if $productType;
}
