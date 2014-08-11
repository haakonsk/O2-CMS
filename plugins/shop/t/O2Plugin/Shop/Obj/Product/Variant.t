use strict;
use utf8;
#----------------------------------------------------------------- Dependencies
use Test::More qw(no_plan);
use O2::Context;
use Data::Dumper;
use O2::Script::Test::Common;
#------------------------------------------------------------- Dependency tests
diag "\nFunction test for O2Plugin::Shop::Obj::Product::Variant\n";
use_ok('O2Plugin::Shop::Obj::Product::Variant');
use_ok('O2Plugin::Shop::Mgr::Product::VariantManager');
use_ok('O2Plugin::Shop::Obj::Product::Variant::Option');
use_ok('O2Plugin::Shop::Mgr::Product::Variant::OptionManager');
#--------------------------------------------------------------- Creation tests
diag "\nCreating variant object\n";
my $context = O2::Context->new();
my $variant = $context->getSingleton('O2Plugin::Shop::Mgr::Product::VariantManager')->newObject();
isa_ok( $variant => 'O2Plugin::Shop::Obj::Product::Variant');
#--------------------------------------------------------------- Function tests
diag "\nChecking for what functions that are available for this product\n";
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'save' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'delete' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'deletePermanently' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'setMetaName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'getMetaName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'setName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'getName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'getDescription' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'setDescription' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'setOptionIds' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant', 'getOptionIds' );
#----------------------------------------------------------- Data storage tests
diag "\nWriting data to variant\n";
diag "metaName : Shoesize\n";
$variant->setMetaName( 'Shoesize' );
diag "name : Skostørrelse\n";
$variant->setName( 'Shoesize' );
diag "description : This variant manages shoesizes\n";
$variant->setDescription('This variant manages shoesizes');
diag "unit : str\n";
$variant->setUnit( 'str' );
$variant->save();
#--------------------------------------------------------- Option storage tests
diag "\nCreating two options\n";
my $optionMgr = $context->getSingleton('O2Plugin::Shop::Mgr::Product::Variant::OptionManager');
my $option1 = $optionMgr->newObject();
my $option2 = $optionMgr->newObject();
isa_ok( $option1 => 'O2Plugin::Shop::Obj::Product::Variant::Option');
isa_ok( $option2 => 'O2Plugin::Shop::Obj::Product::Variant::Option');
diag "\nFilling up options with data\n";
$option1->setMetaName( 'Shoesize' );
$option2->setMetaName( 'Shoesize' );
$option1->setValue( 'L' );
$option2->setValue( 'XL' );
$option1->setPriceModifierExVat('+10');
$option2->setPriceModifierExVat('-5');
$option1->save();
$option2->save();
diag "\nAdding options to variant\n";
$variant->setOptionIds( ( $option1->getId(), $option2->getId()) );
#--------------------------------------------------------- Data retrieval tests
diag "\nReading data from variant\n";
my $result = '';
my @result = ();
ok( $result = $variant->getMetaName(), "Read metaName: $result" );
ok( $result = $variant->getName(), "Read name: $result");
ok( $result = $variant->getDescription(), "Read description: $result" );
ok( $result = $variant->getUnit(), "Read unit: $result" );
ok( @result = $variant->getOptionIds(), "Read optionIds: ".Dumper(\@result) );

diag "\nReading all options as objects:\n";
my @options = $variant->getOptions();
foreach my $option ( @options ) {
  isa_ok( $option => 'O2Plugin::Shop::Obj::Product::Variant::Option', "object ".$option->getId().", ".$variant->getName()." : ".$variant->getUnit()." : ".$option->getValue());
}
#---------------------------------------------------------------------- Cleanup
diag "\nTest complete, cleaning up...\n";
$variant->deletePermanently();
$option1->deletePermanently();
$option2->deletePermanently();
