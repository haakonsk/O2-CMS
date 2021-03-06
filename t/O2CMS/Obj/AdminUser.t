# This file was originally auto-generated by O2 with contents hashing to 95da3d06d0f67ee364e5f5cb558e1f11
use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2CMS::Mgr::AdminUserManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2CMS::Mgr::AdminUserManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2CMS::Obj::AdminUser/O2CMS::Mgr::AdminUserManager');
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId( getTestObjectId() );
$newObj->setKeywordIds( getTestObjectId(), getTestObjectId() );
$newObj->setMetaOwnerId( getTestObjectId() );
$newObj->setMetaName("Test-varchar");
$newObj->setCountryCode('aa');
$newObj->setEmail("Test-varchar");
$newObj->setCellPhone("Test-varchar");
$newObj->setLastName("Test-varchar");
$newObj->setAddress("Test-varchar");
$newObj->setGender('male');
$newObj->setFirstName("Test-varchar");
$newObj->setPhone("Test-varchar");
$newObj->setBirthDate( $context->getDateFormatter()->dateFormat(time, 'yyyy-MM-dd HH:mm:ss') );
$newObj->setMiddleName("Test-varchar");
$newObj->setAttributes('a' => 'one', 'b' => 'two', );
$newObj->setPostalCode("Test-varchar");
$newObj->setPostalPlace("Test-varchar");
$newObj->setPassword("Test-varchar");
$newObj->setUsername("Test-varchar");
$newObj->save();

ok($newObj->getId() > 0, 'Object saved ok');

my $dbObj = $context->getObjectById( $newObj->getId() );
ok($dbObj, 'getObjectById returned something') or BAIL_OUT("Couldn't get object from database");

is( $dbObj->getMetaClassName(), $newObj->getMetaClassName(), 'metaClassName retrieved ok.' );
is( $dbObj->getMetaStatus(), $newObj->getMetaStatus(), 'metaStatus retrieved ok.' );
is( $dbObj->getMetaParentId(), $newObj->getMetaParentId(), 'metaParentId retrieved ok.' );
is_deeply( [ $dbObj->getKeywordIds() ], [ $newObj->getKeywordIds() ], 'keywordIds retrieved ok.' );
is( $dbObj->getMetaCreateTime(), $newObj->getMetaCreateTime(), 'metaCreateTime retrieved ok.' );
is( $dbObj->getId(), $newObj->getId(), 'id retrieved ok.' );
is( $dbObj->getMetaChangeTime(), $newObj->getMetaChangeTime(), 'metaChangeTime retrieved ok.' );
is( $dbObj->getMetaOwnerId(), $newObj->getMetaOwnerId(), 'metaOwnerId retrieved ok.' );
is( $dbObj->getMetaName(), $newObj->getMetaName(), 'metaName retrieved ok.' );
is( $dbObj->getCountryCode(), $newObj->getCountryCode(), 'countryCode retrieved ok.' );
is( $dbObj->getEmail(), $newObj->getEmail(), 'email retrieved ok.' );
is( $dbObj->getCellPhone(), $newObj->getCellPhone(), 'cellPhone retrieved ok.' );
is( $dbObj->getLastName(), $newObj->getLastName(), 'lastName retrieved ok.' );
is( $dbObj->getAddress(), $newObj->getAddress(), 'address retrieved ok.' );
is( $dbObj->getGender(), $newObj->getGender(), 'gender retrieved ok.' );
is( $dbObj->getFirstName(), $newObj->getFirstName(), 'firstName retrieved ok.' );
is( $dbObj->getPhone(), $newObj->getPhone(), 'phone retrieved ok.' );
is( $dbObj->getBirthDate()->format('yyyy-MM-dd HH:mm:ss'), $newObj->getBirthDate()->format('yyyy-MM-dd HH:mm:ss'), 'birthDate retrieved ok.' );
is( $dbObj->getMiddleName(), $newObj->getMiddleName(), 'middleName retrieved ok.' );
is_deeply( { $dbObj->getAttributes() }, { $newObj->getAttributes() }, 'attributes retrieved ok.' );
is( $dbObj->getPostalCode(), $newObj->getPostalCode(), 'postalCode retrieved ok.' );
is( $dbObj->getPostalPlace(), $newObj->getPostalPlace(), 'postalPlace retrieved ok.' );
is( $dbObj->getPassword(), $newObj->getPassword(), 'password retrieved ok.' );
is( $dbObj->getUsername(), $newObj->getUsername(), 'username retrieved ok.' );

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
