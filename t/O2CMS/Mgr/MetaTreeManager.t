use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';
use_ok 'O2::Mgr::MetaTreeManager';

my $context = O2::Context->new();
my $site = $context->getSingleton('O2CMS::Mgr::SiteManager')->getSiteByHostname( $context->getHostname() );

my $treeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');

my $o = $treeMgr->getObjectByPath('/Installation/' . $site->getHostname());
isa_ok($o, 'O2CMS::Obj::Site', 'Object is a Site-object');

my $categoryMgr = $context->getSingleton('O2CMS::Mgr::CategoryManager');

my $parent = $categoryMgr->newObject();
$parent->setMetaName('Parent');
$parent->save();

my $subCategory = $categoryMgr->newObject();
$subCategory->setMetaParentId( $parent->getId() );
$subCategory->setMetaName(     'Sub category'   );
$subCategory->save();

my @ids = $treeMgr->getContainerIdsRecursive( $parent->getId() );
is_deeply(\@ids, [$parent->getId(), $subCategory->getId()], 'getContainerIdsRecursive()');

END {
  $subCategory->deletePermanently() if $subCategory;
  $parent->deletePermanently()      if $parent;
}
