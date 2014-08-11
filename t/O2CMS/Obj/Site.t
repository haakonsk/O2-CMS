use Test::More qw(no_plan);

use O2::Context;
my $context = O2::Context->new();

# setup test environment
mkdir 'data';
mkdir 'data/site';

my ($installation) = $context->getSingleton('O2CMS::Mgr::InstallationManager')->objectSearch( -limit => 1 );

my $siteMgr = $context->getSingleton('O2CMS::Mgr::SiteManager');
my $site = $siteMgr->newObject();
$site->setMetaParentId( $installation->getId() );
$site->setMetaName(      'testsite.redpill-linpro.com' );
$site->setHostname(      'testsite.redpill-linpro.com' );
$site->setPortNumber(    80                            );
$site->setDirectoryName( 'data/site'                   );
$site->setTitle(         'testsite.redpill-linpro.com' );
$site->save();


my $dbSite = $context->getObjectById( $site->getId() );
is( $site->getMetaName(),   $dbSite->getMetaName(),   'getMetaName()'   );
is( $site->getHostname(),   $dbSite->getHostname(),   'getHostname()'   );
is( $site->getPortNumber(), $dbSite->getPortNumber(), 'getPortNumber()' );

my $site2 = $siteMgr->getSiteByHostname('testsite.redpill-linpro.com');
ok($site2, 'getSiteByHostname()');

# Clean up
END {
  rmdir 'data/site';
  rmdir 'data';
  $site->deletePermanently( recursive => 1 ) if $site;
}
