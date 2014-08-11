#!/usr/bin/perl

use strict;
use O2::Context;
use O2::Mgr::PropertyManager;
use O2::Mgr::UniversalManager;

my $context = new O2::Context();
my $propertyMgr = O2::Mgr::PropertyManager->new(context=>$context);
my $objectId = $ARGV[0];
my $name = $ARGV[1];
my $value = $ARGV[2];

die "usage $0: objectId propertyName {value}" if @ARGV==0;
if( @ARGV==3 ) {
  $propertyMgr->setPropertyValue($objectId, $name, $value);
}
my $property = $propertyMgr->getProperty($objectId, $name);
if( $property ) {
  print "value: ", $property->getValue(),"\n";
  print "getProperyValue says: ",$propertyMgr->getPropertyValue($objectId, $name) ,"\n";
  print "originatorId: ", $property->getOriginatorId(),"\n";
  print "isInherited: ", $property->isInherited(),"\n";
} else {
  print "Property not found\n";
}




__END__
my $objectId = 24;

print $propertyMgr->getPropertyValue($objectId,'color'),"\n";

my $add = chr(65+int(rand(10)));
$property->setValue( $property->getValue().$add); 
$property->save();

my $universalMgr = O2::Mgr::UniversalManager->new(context=>$context);
my $object = $universalMgr->getObjectById($objectId);
print "property from object: ", $object->getPropertyValue('color'),"\n";
$object->setPropertyValue('color', 'green');

print "New property set through meta: ", $propertyMgr->getPropertyValue($objectId,'color'),"\n";

#$propertyMgr->deletePropertyValue($objectId,'color');

