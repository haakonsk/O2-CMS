#---------------------------------------------------------------------------------------------- Dependencies
use Test::More qw(no_plan);
use O2::Context;
use strict;
use Data::Dumper;
use O2::Script::Test::Common;

my $context = O2::Context->new();
my $site = ($context->getSingleton('O2::Mgr::UniversalManager')->getObjectsByClassNameAndStatus('O2CMS::Obj::Site', 'new'))[0];

#------------------------------------------------------------------------------------------ Dependency tests
diag "\nFunction test for O2Plugin::Shop::Obj::Product::Category\n";
use_ok( 'O2Plugin::Shop::Obj::Product::Category' );
use_ok( 'O2Plugin::Shop::Mgr::Product::CategoryManager' );

#--------------------------------------------------------------------------------------------- Creation test
diag "\nCreating two product categories\n";
my $productCategoryManager = $context->getSingleton('O2Plugin::Shop::Mgr::Product::CategoryManager');

my $category1 = '';
ok( $category1 = $productCategoryManager->newObject(), 'Successfully created category1' );

diag "\nChecking object type\n";
isa_ok( $category1 => 'O2Plugin::Shop::Obj::Product::Category', 'category1' );

#-------------------------------------------------------------------------------------- data assignment test
diag "\nAssigning values to category1\n";
ok( $category1->setMetaName('category1'), "Successfully assigned metaName to category1" );
ok( $category1->setName('category1'), "Successfully assigned name to category1" );
ok( $category1->setDescription('This is the description for category1') ,"Successfully assigned description to category1" );
ok( $category1->setDirectoryName('category1'), "Successfully assigned directoryname to category1" );
ok( $category1->setMetaParentId( $site->getId() ), "Successfully assigned metaParentId to category1" );

diag "\nStoring category1\n";
$category1->save();
my $objectId = '';
ok( $objectId = $category1->getId(), "Successfully stored category1, objectId: $objectId" );

diag "\nChild categories\n";
my $category2 = '';
ok( $category2 = $productCategoryManager->newObject(), 'Successfully created category2' );
isa_ok( $category2 => 'O2Plugin::Shop::Obj::Product::Category', 'category2' );

diag "\nAssigning values to category2\n";
ok( $category2->setMetaName('category2'), "Successfully assigned metaName to category2" );
ok( $category2->setName('category2'), "Successfully assigned name to category2" );
ok( $category2->setDescription('This is the description for category2') ,"Successfully assigned description to category2" );
ok( $category2->setDirectoryName('category2'), "Successfully assigned directoryname to category2" );
ok( $category2->setMetaParentId($objectId), "Successfully assigned metaParentId to category2" );

diag "\nStoring category2\n";
$category2->save();
my $objectId = '';
ok( $objectId = $category2->getId(), "Successfully stored category2, objectId: $objectId" );

diag "\nProducts\n";
use_ok('O2Plugin::Shop::Obj::Product');
use_ok('O2Plugin::Shop::Mgr::ProductManager');
my $productMgr = $context->getSingleton('O2Plugin::Shop::Mgr::ProductManager');
my $product1 = $productMgr->newObject();
my $product2 = $productMgr->newObject();
isa_ok( $product1 => 'O2Plugin::Shop::Obj::Product');
isa_ok( $product2 => 'O2Plugin::Shop::Obj::Product');   

ok( $product1->setMetaName('Testproduct1'), "Assigned metaName to product1" );
ok( $product1->setName('Testprodukt1'), "Assigned name to product1" );
ok( $product1->setSummary('Dette er et testprodukt' ), "Assigned summary to product1" );
ok( $product1->setDescription('Dette produktet er kun for testing' ), "Assigned description to product1" );
ok( $product1->setIsActive(1), "Activating product1" );

ok( $product2->setMetaName('Testproduct2'), "Assigned metaName to product2" );
ok( $product2->setName('Testprodukt2'), "Assigned name to product2" );
ok( $product2->setSummary('Dette er et testprodukt' ), "Assigned summary to product2" );
ok( $product2->setDescription('Dette produktet er kun for testing' ), "Assigned description to product2" );
ok( $product2->setIsActive(1), "Activating product2" );

my $productType = $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->newObject();
foreach my $locale ($productType->getAvailableLocales()) {
  $productType->setName("TheProductType $locale");
}
$product1->setProductType($productType);
$product2->setProductType($productType);

$product1->save();
diag "\nStored product1: objectId: ".$product1->getId()."\n";

$product2->save();
diag "\nStored product2: objectId: ".$product2->getId()."\n";

diag "\nAdding category2, product1 and product2 as child of category1\n";
my @children = ( $category2->getId(), $product1->getId(), $product2->getId() );

ok( $category1->setChildObjectIds( @children ), "Successfully assigned children to category1" );
#------------------------------------------------------------------------------------- Value retrieval tests
diag "\nReading values from category1\n";
 
my $result = '';
my @result = ();

ok( $result = $category1->getId(), "Reading objectId to category1: $result" );
ok( $result = $category1->getMetaName(), "Reading metaName from category1: $result" );
ok( $result = $category1->getName(), "Reading name from category1: $result" );
ok( $result = $category1->getDescription(), "Reading description for category1: $result" );
ok( $result = $category1->getDirectoryName(), "Reading directoryName for category1: $result" );
ok( $result = $category1->getMetaParentId(), "Reading metaParentId for category1: $result" ); 

ok( @result = $category1->getChildObjectIds(), "Reading children to category1: @result" );

my @result = ();
ok( @result = @{ $category1->getSubCategories() }, "Reading subCategories for category1:" );
foreach my $subCategory ( @result ) {
  isa_ok( $subCategory => 'O2Plugin::Shop::Obj::Product::Category', $subCategory->getId()." : ".$subCategory->getName() );
}

my @result = ();
ok( @result = @{ $category1->getProducts() }, "Reading products for category1:" );
foreach my $product ( @result ) {
  isa_ok( $product => 'O2Plugin::Shop::Obj::Product', $product->getId()." : ".$product->getName() );
}

#---------------------------------------------------------------------------------------- Manipulation tests
diag "\nManipulation on children\n";
ok( $category1->removeProduct( $product1->getId() ), "Successfully removed product1 from category1" );

ok( @result = @{ $category1->getProducts() }, "Reading products for category1:" );
foreach my $product ( @result ) {
   isa_ok( $product => 'O2Plugin::Shop::Obj::Product', $product->getId()." : ".$product->getName() );
}

ok( $category1->addProduct( $product1->getId() ), "Successfully added product1 from category1" );

ok( @result = @{ $category1->getProducts() }, "Reading products for category1:" );
foreach my $product ( @result ) {
   isa_ok( $product => 'O2Plugin::Shop::Obj::Product', $product->getId()." : ".$product->getName() );
}

ok( $category1->removeSubCategory( $category2->getId() ), "Successfully removed category2 from category1" );

my @result = $category1->getSubCategories();
ok( !@result, "No subCategories found" );

#--------------------------------------------------------------------------------------------------- Cleanup
sub END {
  $category1->deletePermanently( recursive => 1 ) if $category1;
  $product1->deletePermanently()                  if $product1;
  $product2->deletePermanently()                  if $product2;
  $productType->deletePermanently()               if $productType;
}
