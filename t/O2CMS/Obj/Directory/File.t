# This file was originally auto-generated by O2 with contents hashing to 5879cdec7984dd593a95615dc292bcc7
use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

use_ok 'O2CMS::Mgr::Directory::FileManager';

use O2 qw($context $config);

my @localeCodes = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2CMS::Mgr::Directory::FileManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2CMS::Obj::Directory::File/O2CMS::Mgr::Directory::FileManager');
$newObj->setMetaStatus("Test-varchar");
$newObj->setMetaParentId( getTestObjectId() );
$newObj->setKeywordIds( getTestObjectId(), getTestObjectId() );
$newObj->setMetaOwnerId( getTestObjectId() );
$newObj->setMetaName("Test-varchar");
$newObj->setFile( getTestObjectId() );
$newObj->setFilename("Test-varchar");
$newObj->setImportEpoch(time);
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
is( $dbObj->getFileId(), $newObj->getFileId(), 'file retrieved ok.' );
is( $dbObj->getFilename(), $newObj->getFilename(), 'filename retrieved ok.' );
is( $dbObj->getImportEpoch(), $newObj->getImportEpoch(), 'importEpoch retrieved ok.' );

# See if a simple object search works
my @searchResults = $mgr->objectSearch( objectId => $newObj->getId() );
is($searchResults[0]->getId(), $newObj->getId(), 'Search for objectId ok');

END {
  $newObj->deletePermanently() if $newObj;
  deleteTestObjects();
}
