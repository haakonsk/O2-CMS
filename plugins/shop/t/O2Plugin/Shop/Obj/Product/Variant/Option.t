use strict;
#----------------------------------------------------------------- Dependencies
use Test::More qw(no_plan);
use O2::Context;
use O2::Script::Test::Common;
#------------------------------------------------------------- Dependency tests
diag "\nFunction test for O2Plugin::Shop::Obj::Product::Variant::Option\n";
use_ok('O2Plugin::Shop::Obj::Product::Variant::Option');
use_ok('O2Plugin::Shop::Mgr::Product::Variant::OptionManager');
#--------------------------------------------------------------- Creation tests
my $context = O2::Context->new();
my $option = $context->getSingleton('O2Plugin::Shop::Mgr::Product::Variant::OptionManager')->newObject();
isa_ok( $option => 'O2Plugin::Shop::Obj::Product::Variant::Option');
#--------------------------------------------------------------- Function tests
diag "\nChecking for what functions that are available for this product\n";
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'save' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'delete' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'deletePermanently' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'setMetaName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'getMetaName' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'setValue' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'getValue' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'setPriceModifierExVat' );
can_ok( 'O2Plugin::Shop::Obj::Product::Variant::Option', 'getPriceModifierExVat' );
#----------------------------------------------------------- Data storage tests
diag "\nWriting data to option\n";
diag "metaName : Shoesize\n";
$option->setMetaName( 'Shoesize' );
diag "value : XL\n";
$option->setValue( 'XL' );
diag "priceModifier : +10\n";
$option->setPriceModifierExVat('+10');
$option->save();
#--------------------------------------------------------- Data retrieval tests
diag "\nReading data from option\n";
my $result = '';
ok($result = $option->getMetaName(), "metaname: $result");
ok($result = $option->getValue(), "value: $result");
diag "priceModifier: ".$option->getPriceModifierExVat()."\n";
#---------------------------------------------------------------------- Cleanup
diag "\nTest complete, cleaning up...\n";
$option->deletePermanently();
