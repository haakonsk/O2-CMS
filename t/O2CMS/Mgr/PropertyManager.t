use strict;
use Test::More qw(no_plan);

use O2 qw($context);

my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
my $site        = $context->getSingleton('O2CMS::Mgr::SiteManager')->getSiteByHostname( $context->getHostname() );

my $siteId         = $site->getId();
my $installationId = $site->getMetaParentId();

is( $propertyMgr->getPropertyValue($siteId, 'testValue'), undef, 'testValue is undef' );
$propertyMgr->setPropertyValue($siteId, 'testValue', 'blue');
is( $propertyMgr->getPropertyValue($siteId, 'testValue'), 'blue', 'testValue is blue' );
my $property = $propertyMgr->getProperty($siteId, 'testValue');

is( $property->getValue(),         'blue', 'testValue is still blue'   );
is( $property->getOriginatorId(), $siteId, "originatorId is $siteId"   );
is( $property->isInherited(),          '', 'property is not inherited' );

my $newValue = $property->getValue() . chr (65 + int rand 10);
$property->setValue($newValue);

is( $property->getValue(), $newValue, "New value is $newValue" );
is( $propertyMgr->getPropertyValue($siteId, 'testValue'), 'blue', 'But getPropertyValue still returns blue' );

$property->save();

is( $propertyMgr->getPropertyValue($siteId, 'testValue'), $newValue, "getPropertyValue returns $newValue after save" );

$site = $context->getObjectById($siteId);
$site->setPropertyValue('testValue', 'green');

is( $propertyMgr->getPropertyValue($siteId, 'testValue'), 'green', 'getPropertyValue now returns green' );

$propertyMgr->setPropertyValue($installationId, 'testValue', 'red');
$propertyMgr->deletePropertyValue($siteId, 'testValue');
is( $propertyMgr->getPropertyValue($siteId, 'testValue'), 'red', "getPropertyValue returns parent's value (red)" );

END {
  if ($propertyMgr && $siteId) {
    $propertyMgr->deletePropertyValue($installationId, 'testValue');
    is( $propertyMgr->getPropertyValue($siteId, 'testValue'), undef, 'testValue is undef after delete' );
  }
}
