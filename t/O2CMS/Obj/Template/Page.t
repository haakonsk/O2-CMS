use strict;

use Test::More qw(no_plan);

use O2 qw($context $config);

use_ok 'O2CMS::Obj::Template::Slot';
my $context = O2::Context->new();

my $pageMgr = $context->getSingleton('O2CMS::Mgr::Template::PageManager');
my $page = $pageMgr->newObject();
$page->setMetaName( 'page.html'                                 );
$page->setPath(     $config->get('setup.tmpDir') . '/page.html' );
$page->save();

my $dbObj = $context->getObjectById( $page->getId() );
is( $dbObj->getMetaName(), $page->getMetaName(), 'metaName ok' );
is( $dbObj->getPath(),     $page->getPath(),     'path ok'     );

$page->deletePermanently();
