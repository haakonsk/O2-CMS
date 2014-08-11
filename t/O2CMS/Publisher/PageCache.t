use strict;

use Test::More qw(no_plan);

use O2 qw($context);

use O2::Script::Common;
my $installation = getInstallation($context);

my $site = $context->getSingleton('O2CMS::Mgr::SiteManager')->newObject();
$site->setMetaParentId( $installation->getId() );
$site->setMetaName('pageCacheTestSite.redpill-linpro.com');
$site->setHostname('pageCacheTestSite.redpill-linpro.com');
$site->setPortNumber(80);
$site->save();

my $docRoot = $site->getDirectoryName();

my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
$pageCache->enableObjectHtmlCacheForSite($site);
ok( $pageCache->objectHtmlCacheIsEnabledForSite($site), 'Object HTML cache is enabled' );
$pageCache->disableObjectHtmlCacheForSite($site);
ok( !$pageCache->objectHtmlCacheIsEnabledForSite($site), 'Object HTML cache is disabled' );

sub END {
  $site->deletePermanently( recursive => 1 ) if $site;
}
