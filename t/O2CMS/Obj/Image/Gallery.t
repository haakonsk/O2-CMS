# This file was originally auto-generated by O2 with contents hashing to 9b208852000ce915728d243e017ecb32
use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2CMS::Mgr::Image::GalleryManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2CMS::Mgr::Image::GalleryManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2CMS::Obj::Image::Gallery/O2CMS::Mgr::Image::GalleryManager');
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId( getTestObjectId() );
$newObj->setKeywordIds( getTestObjectId(), getTestObjectId() );
$newObj->setMetaOwnerId( getTestObjectId() );
$newObj->setMetaName("Test-varchar");
$newObj->setImageIds( getTestObjectId(), getTestObjectId() );

foreach my $localeCode (@localeCodes) {
  $newObj->setCurrentLocale($localeCode);
  $newObj->setDescription("Test-text ($localeCode)");
  $newObj->setTitle("Test-varchar ($localeCode)");
}
$newObj->save();

ok($newObj->getId() > 0, 'Object saved ok');

my $dbObj = $context->getObjectById( $newObj->getId() );
ok($dbObj, 'getObjectById returned something') or BAIL_OUT("Couldn't get object from database");

is( $dbObj->getMetaClassName(), $newObj->getMetaClassName(), 'metaClassName retrieved ok.' );
is( $dbObj->getMetaStatus(), $newObj->getMetaStatus(), 'metaStatus retrieved ok.' );
is( $dbObj->getMetaChangeTime(), $newObj->getMetaChangeTime(), 'metaChangeTime retrieved ok.' );
is( $dbObj->getMetaParentId(), $newObj->getMetaParentId(), 'metaParentId retrieved ok.' );
is_deeply( [ $dbObj->getKeywordIds() ], [ $newObj->getKeywordIds() ], 'keywordIds retrieved ok.' );
is( $dbObj->getMetaCreateTime(), $newObj->getMetaCreateTime(), 'metaCreateTime retrieved ok.' );
is( $dbObj->getMetaOwnerId(), $newObj->getMetaOwnerId(), 'metaOwnerId retrieved ok.' );
is( $dbObj->getMetaName(), $newObj->getMetaName(), 'metaName retrieved ok.' );
is( $dbObj->getId(), $newObj->getId(), 'id retrieved ok.' );
is_deeply( [ $dbObj->getImageIds() ], [ $newObj->getImageIds() ], 'imageIds retrieved ok.' );
foreach my $localeCode (@localeCodes) {
  $newObj->setCurrentLocale($localeCode);
  $dbObj->setCurrentLocale($localeCode);
  is( $dbObj->getDescription(), $newObj->getDescription(), 'description retrieved ok.' );
  is( $dbObj->getTitle(), $newObj->getTitle(), 'title retrieved ok.' );
}

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
