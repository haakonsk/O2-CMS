use Test::More qw(no_plan);
use_ok 'O2::Context';
my $context = O2::Context->new();
use_ok 'O2CMS::Mgr::WebCategoryManager';
use_ok 'O2::Mgr::PropertyManager';
use_ok 'O2::Mgr::MetaTreeManager';

my ($siteId)          = $context->getDbh()->fetch("select min(objectId) from O2_OBJ_OBJECT where className = 'O2CMS::Obj::Site' and status != 'trashed' and status != 'deleted'");
my $site              = $context->getObjectById($siteId);
my $metaTreeMgr       = O2::Mgr::MetaTreeManager->new( context => $context );
my $frontpageTemplate = $metaTreeMgr->getObjectByPath('/Templates/pages/frontpage.html');

my $doDeletePropertyValue = 0;
my $propertyMgr = O2::Mgr::PropertyManager->new( context => $context );
if (!$site->getPropertyValue('pageTemplateId.O2CMS::Obj::Frontpage')) {
  $site->setPropertyValue('pageTemplateId.O2CMS::Obj::Frontpage', $frontpageTemplate->getId());
  $doDeletePropertyValue = 1;
}

my $webCategoryMgr = O2CMS::Mgr::WebCategoryManager->new( context => $context );
my $webCategory = $webCategoryMgr->newObject();
$webCategory->setMetaName('tezt');
$webCategory->setDirectoryName('tezt');
$webCategory->setMetaParentId($siteId);
$webCategory->save();

my $dbObj = $context->getObjectById( $webCategory->getId() );
is( $webCategory->getMetaName(),      $dbObj->getMetaName(),      'metaName ok'      );
is( $webCategory->getDirectoryName(), $dbObj->getDirectoryName(), 'directoryName ok' );
is( $webCategory->getMetaParentId(),  $dbObj->getMetaParentId(),  'metaParentId ok'  );

END {
  $site->deletePropertyValue('pageTemplateId.O2CMS::Obj::Frontpage') if $doDeletePropertyValue;
  $webCategory->deletePermanently( recursive => 1)                   if $webCategory;
}
