use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';
use O2::Script::Test::Common;

my $context = O2::Context->new();
use_ok 'O2CMS::Mgr::MenuManager';
use_ok 'O2::Mgr::UniversalManager';
use_ok 'O2::Mgr::MetaTreeManager';

# setup test environment
my $dataDirExisted = -e 'data';
my $siteDirExisted = -e 'data/site';
mkdir 'data';
mkdir 'data/site';
my $universalMgr = O2::Mgr::UniversalManager->new(context=>$context);
my $metaTreeMgr = O2::Mgr::MetaTreeManager->new(context=>$context);

my $installation = $universalMgr->newObjectByClassName('O2CMS::Obj::Installation');
$installation->setMetaName('Test installation');
$installation->setVersion(1);
$installation->save();
my $frontpageTemplate = $metaTreeMgr->getObjectByPath('/Templates/pages/frontpage.html');
$installation->setPropertyValue('pageTemplateId.O2CMS::Obj::Frontpage', $frontpageTemplate->getId());

my $site = $universalMgr->newObjectByClassName('O2CMS::Obj::Site');
$site->setMetaParentId($installation->getId());
$site->setMetaName('www.test.com');
$site->setHostname('www.test.com');
$site->setDirectoryName('data/site');
$site->save();

my $webCategory = $universalMgr->newObjectByClassName('O2CMS::Obj::WebCategory');
$webCategory->setMetaParentId($site->getId());
$webCategory->setMetaName('webcategoryMetaName');
$webCategory->setDirectoryName('webcategory');
my @locales = ($webCategory->getCurrentLocale(), 'fa_KE');
foreach my $locale (@locales) {
  $webCategory->setCurrentLocale($locale);
  $webCategory->setTitle("webcategory $locale");
}
$webCategory->save();

my $webCategory2 = $universalMgr->newObjectByClassName('O2CMS::Obj::WebCategory');
$webCategory2->setMetaParentId($site->getId());
$webCategory2->setMetaName('webcategoryMetaName2');
$webCategory2->setDirectoryName('webcategory2');
$webCategory2->setTitle("webcategory2 title");
$webCategory2->save();

my $webCategory3 = $universalMgr->newObjectByClassName('O2CMS::Obj::WebCategory');
$webCategory3->setMetaParentId($webCategory->getId());
$webCategory3->setMetaName('webcategoryMetaName3');
$webCategory3->setTitle("webcategory3 title");
$webCategory3->setDirectoryName('webcategory3');
$webCategory3->save();

diag "site:",$site->getId(), ",webCategory:",$webCategory->getId(),", webCategory2:",$webCategory2->getId(),", webCategory3:",$webCategory3->getId(),"\n";

# test menu object
my $menuMgr = $context->getSingleton('O2CMS::Mgr::MenuManager');
my $menu = $menuMgr->newObject();
$menu->setMetaParentId($site->getId());
$menu->setTopLevelId($site->getId());
$menu->setMetaName('Test menu');
$menu->includeNewMenuItems();
my $menuItem = $menu->getMenuItemByObjectId($webCategory->getId());
foreach my $locale (@locales) {
  $menu->setCurrentLocale($locale);
  $menuItem->setDescription("category1 $locale");
  $menuItem->setPosition(2);
}
$menu->addMenuItem($menuItem);
#$menuItem->setExpandable(1);
#
#my $menuItem2 = $menu->getCreatedMenuItemByObjectId($webCategory2->getId());
#$menuItem2->setDescription("category2");
ok($menu->getMenuItemByObjectId($webCategory->getId()) && $menu->getMenuItemByObjectId($webCategory2->getId()) && $menu->getMenuItemByObjectId($webCategory3->getId()), 'getMenuItemByObjectId() for new menu');
ok(scalar $menu->getMenuItems()==3, 'getMenuItems() for new menu');

$menu->save();
ok($menu->getId()>0, 'Menu saved');

my $dbMenu = $menuMgr->getObjectById($menu->getId());
my $dbMenuItem = $dbMenu->getMenuItemByObjectId($webCategory->getId());
ok($dbMenuItem->getTargetId()==$webCategory->getId(), 'getMenuItemById()');
#ok($dbMenuItem->getUsedLocales()==2, 'Webcategory has 2 locales');
my $dbMenuItem2 = $dbMenu->getMenuItemByObjectId($webCategory2->getId());
#ok($dbMenuItem2->getUsedLocales()==1, 'Webcategory2 has 1 locale');

my @menuItemsAt = $dbMenu->getMenuItemsAt($site->getId());
ok( scalar @menuItemsAt==2, 'getMenuItemsAt() correct number of elements');
ok(scalar $dbMenu->getMenuItems()==3, 'getMenuItems() for saved menu');

diag $dbMenu->asTreeString();

END {
  $menu->deletePermanently()                         if $menu;
  $installation->deletePermanently( recursive => 1 ) if $installation;
  rmdir 'data/site' unless $siteDirExisted;
  rmdir 'data'      unless $dataDirExisted;
}
