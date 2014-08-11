package O2CMS::Mgr::Site::SitemapManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2CMS::Obj::Site::Sitemap;

#----------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Site::Sitemap',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    cronIntervalDays          => { type => 'int'     },
    cronFirstTimeEpoch        => { type => 'int'     },
    epochOfPreviousSubmission => { type => 'int'     },
    metatagName               => { type => 'varchar' },
    metatagValue              => { type => 'varchar' },
    #-----------------------------------------------------------------------------
  );
}
#----------------------------------------------------------------------
sub getObjectByParentId {
  my ($obj, $parentId) = @_;
  my $site = $context->getObjectById($parentId);

  my $query = "select objectId from O2_OBJ_OBJECT where className = 'O2CMS::Obj::Site::Sitemap' and parentId = ? and status not in ('trashed', 'trashedAncestor', 'deleted')";
  my @objectIds = $db->selectColumn($query, $parentId);

  die "More than one sitemap for this site (id=$parentId)" if scalar @objectIds > 1;
  my $sitemap;
  if (scalar @objectIds == 0) {
    $sitemap = $obj->newObject();
    $sitemap->setMetaParentId($parentId);
    $sitemap->setMetaName('Sitemap for ' . $site->getMetaName());
  }
  elsif (scalar @objectIds == 1) {
    my $sitemapId = $objectIds[0];
    $sitemap = $context->getObjectById($sitemapId);
  }

  return $sitemap;
}
#----------------------------------------------------------------------
sub generateSitemap { # Called from cron jobs
  my ($obj, $objectId) = @_;
  my $sitemap = $context->getObjectById($objectId);
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new();
  my $method = 'generateSitemap';
  $method   .= 'AndSubmit' if $sitemap->getCronGenerateAndSubmit();
  # XXX Domain!
  my $url = "/o2cms/SiteDiagnostic/$method?isCron=1&sitemapId=" . $sitemap->getId();
  my $response = $ua->get($url);
  return '' if $response->is_success();
  return $response->status_line();
}
#----------------------------------------------------------------------
1;
