package O2CMS::Backend::Gui::Site::Sitemaps;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

# Todo:
#  Cron job

#----------------------------------------------------------------------
sub init {
  my ($obj) = @_;

  my $sitemap;
  my $sitemapId = $obj->getParam('objectId');
  if (!$sitemapId) {
    die 'sitemapId or parentId missing' unless $obj->getParam('parentId');
    require O2CMS::Mgr::Site::SitemapManager;
    my $sitemapMgr = O2CMS::Mgr::Site::SitemapManager->new();
    $sitemap = $sitemapMgr->getObjectByParentId( $obj->getParam('parentId') );
    $sitemap->save();
  }
  else {
    $sitemap = $context->getObjectById($sitemapId);
  }

  my $site = $context->getObjectById( $sitemap->getMetaParentId() );
  $obj->display(
    'init.html',
    sitemap       => $sitemap,
    site          => $site,
    sitemapExists => -f $context->getEnv('O2CUSTOMERROOT') . '/../' . $site->getMetaName() . '/' . $obj->_getSitemapFilename() ? 1 : 0,
  );
}
#----------------------------------------------------------------------
sub saveVerificationMetaTag {
  my ($obj) = @_;
  my %q = $obj->getParams();

  my $sitemap = $context->getObjectById( $q{sitemapId} );

  my $tag = $q{verificationMetaTag};
  my ($dummy, $name, $dummy2, $value) = $tag =~ m{ name=([\"\']) (.*?) \1  \s+  content=([\"\']) (.*?) \3 }xms;

  if (!$name || !$value) {
    $obj->error( $obj->getLang()->getString('o2.Site.Sitemaps.errorIncorrectMetaTag') );
  }

  $sitemap->setMetatagName($name);
  $sitemap->setMetatagValue($value);
  $sitemap->save();

  return 1;
}
#----------------------------------------------------------------------
sub submitSitemap {
  my ($obj) = @_;
  my $sitemap = $context->getObjectById( $obj->getParam('sitemapId') );
  my $site    = $context->getObjectById( $sitemap->getMetaParentId() );
  my $siteName = $site->getMetaName();
  my $sitemapUrl = "http://$siteName/" . $obj->_getSitemapFilename();
  return 1 if $obj->_submitSitemapToGoogle($sitemapUrl, $sitemap);
  $obj->error( $obj->getLang()->getString('o2.Site.Sitemaps.errorCouldntSubmitToGoogle') );
}
#----------------------------------------------------------------------
sub _initCounters {
  my ($obj) = @_;
  $obj->{counters} = {};
  $obj->_addCounter('numArticles',      $obj->getLang()->getString('o2.Site.Sitemaps.lblNumArticles'),      0);
  $obj->_addCounter('numWebCategories', $obj->getLang()->getString('o2.Site.Sitemaps.lblNumWebCategories'), 1);
  $obj->_addCounter('numProducts',      $obj->getLang()->getString('o2.Site.Sitemaps.lblNumProducts'),      0);
}
#----------------------------------------------------------------------
sub generateSitemap {
  my ($obj) = @_;

  my $autoflush = $context->getSingleton('O2::Gui::Autoflush');
  $autoflush->enableAutoScroll();
  $autoflush->printHeader(
    foregroundColor => '#af8',
    backgroundColor => 'black',
  );

  my $sitemapId = $obj->getParam('sitemapId');
  die "sitemapId missing" unless $sitemapId;
  my $sitemap   = $context->getObjectById( $sitemapId );
  my $site      = $context->getObjectById( $sitemap->getMetaParentId() );
  $obj->{path}  = []; # Needed to resolve symbolic links

  $obj->{depth} = 0;
  $obj->_initCounters();
  $autoflush->printLine( $obj->getString('o2.Site.Sitemaps.walkingThroughDirectories') . ':' );
  $autoflush->printLine();

  my @entries;

  my @locales = $site->isMultilingual() ? $site->getUsedLocales() : $site->getAvailableLocales();
  foreach my $locale (@locales) {
    push @entries, {
      url      => $site->getUrl() . "?forceLocale=$locale",
      priority => 1,
    };
  }
  push @entries, $obj->_addSitemapEntries( $site->getId(), $site ); # Start recursion

  require O2::Template;
  my $tmpl = O2::Template->newFromFile( $context->getEnv('O2ROOT') . '/var/templates/Site/Sitemaps/sitemap.xml' );
  my $sitemapXmlRef = $tmpl->parse(
    entries => \@entries,
  );

  my $siteName        = $site->getMetaName();
  my $sitemapFilename = $obj->_getSitemapFilename();
  my $sitemapPath     = $context->getEnv('O2CUSTOMERROOT') . "/../$siteName/$sitemapFilename";

  $autoflush->printLine();

  $obj->_saveXmlFile($sitemapPath, $sitemapXmlRef);
  $obj->_saveRobotsTxt();

  $autoflush->printLine( $obj->getString('o2.Site.Sitemaps.addedEntries', numEntries => scalar(@entries)) );
  foreach my $counterId (keys %{$obj->{counters}}) {
    my $counter = $obj->{counters}->{$counterId};
    $autoflush->printLine($counter->{desc} . ': ' . $counter->{count});
  }
  $autoflush->printLine();

  print "<script type='text/javascript'> parent.setUploadButtonVisible(); parent.renameGenerateButton(); parent.setDownloadButtonVisible(); top.endWork(); </script>";
  $autoflush->printLine( $obj->getString('o2.Site.Sitemaps.done') );
  $autoflush->printFooter();
}
#----------------------------------------------------------------------
sub _addSitemapEntries {
  my ($obj, $categoryId, $site) = @_;

  $obj->{depth}++;
  my @entries;
  my $domain = $site->getMetaName();
  my $category = $context->getObjectById($categoryId);
  push @{$obj->{path}}, $category;

  my $autoflush = $context->getSingleton('O2::Gui::Autoflush');
  $autoflush->printLine( ('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' x ($obj->{depth}-1) )   .   $category->getMetaName());
  my @children = $category->getChildren();
  foreach my $child (@children) {

    next if $child->isDeleted();

    if ($child->getPropertyValue('allowIndexing') eq 'no' && $child->isa('O2CMS::Obj::WebCategory')) {
      $obj->_addRobotsDisallowEntry( $child->getUrl() );
      next;
    }

    if ($child->isa('O2CMS::Obj::WebCategory')) {
      my $url = $child->getUrl();
      $url = $obj->_getSymbolicUrl($child)  if $url !~ m{ \A https?://$domain  }xms;
      my @locales = $child->isMultilingual() ? $child->getUsedLocales() : $child->getAvailableLocales();
      foreach my $locale (@locales) {
        push @entries, {
          url      => $url . "?forceLocale=$locale",
          priority => 0.7,
        };
      }
      push @entries, $obj->_addSitemapEntries( $child->getId(), $site );
      $obj->_incCounter('numWebCategories');
    }
    elsif ($child->isa('O2CMS::Obj::Article')) {
      if ($child->isSearchable()) {
        my $url = $category->getUrl();
        $url = $obj->_getSymbolicUrl($category)  if $url !~ m{ \A https?://$domain  }xms;
        my @locales = $child->isMultilingual() ? $child->getUsedLocales() : $child->getAvailableLocales();
        foreach my $locale (@locales) {
          push @entries, {
            url      => $url . $child->getId() . ".o2?forceLocale=$locale",
            priority => 0.4,
          };
        }
        $obj->_incCounter('numArticles');
      }
    }
  }
  $obj->{depth}--;
  pop @{$obj->{path}};
  return @entries;
}
#----------------------------------------------------------------------
sub updateCron {
  my ($obj) = @_;

  my %q = $obj->getParams();
  my $interval  = $q{cronInterval};
  my $firstTime = $q{firstTime};
  my $sitemapId = $q{sitemapId};

  my ($year, $month, $day, $hour, $second)   =   $firstTime =~ m{ (\d\d\d\d) - (\d\d) - (\d\d) [ ] (\d\d) : (\d\d) }xms;
  my $firstTimeEpoch = $context->getSingleton('O2::Util::DateCalc')->toEpoch($year, $month, $day, $hour, $second);

  my $sitemap = $context->getObjectById($sitemapId);
  $sitemap->setCronIntervalDays(   $interval       );
  $sitemap->setCronFirstTimeEpoch( $firstTimeEpoch );
  $sitemap->save();

  # XXX Update cron job..

  return 1;
}
#----------------------------------------------------------------------
sub _submitSitemapToGoogle {
  my ($obj, $sitemapUrl, $sitemap) = @_;
  $sitemapUrl = $cgi->urlEncode($sitemapUrl);
  my $url = "http://www.google.com/webmasters/sitemaps/ping?sitemap=$sitemapUrl";
  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new();
  my $response = $ua->get($url);
  if ($response->is_success()) {
    $sitemap->setEpochOfPreviousSubmission( time() );
    $sitemap->save();
    return 1;
  }
  return 0;
}
#----------------------------------------------------------------------
sub _saveXmlFile {
  my ($obj, $sitemapPath, $sitemapXmlRef) = @_;
  open my $FH, '>', $sitemapPath or die "Couldn't open $sitemapPath for writing: " . $!;
  print {$FH} ${$sitemapXmlRef}  or die "Couldn't write to file $sitemapPath: "    . $!;
  close $FH;
  my $autoflush = $context->getSingleton('O2::Gui::Autoflush');
  $autoflush->printLine( $obj->getString('o2.Site.Sitemaps.sitemapFileSaved') );
}
#----------------------------------------------------------------------
sub _saveXmlGzFile {
  my ($obj, $gzSitemapPath, $sitemapXmlRef) = @_;

  use Compress::Zlib;
  my $gz = gzopen($gzSitemapPath, 'wb') or die $!;
  $gz->gzwrite($sitemapXmlRef);
  $gz->gzclose();
}
#----------------------------------------------------------------------
sub _getSitemapFilename {
  return "sitemap.xml";
}
#----------------------------------------------------------------------
sub _addCounter {
  my ($obj, $id, $desc, $count) = @_;
  $obj->{counters}->{$id} = {
    desc  => $desc,
    count => $count,
  };
}
#----------------------------------------------------------------------
sub _incCounter {
  my ($obj, $id) = @_;
  $obj->{counters}->{$id}->{count}++;
}
#----------------------------------------------------------------------
sub _addRobotsDisallowEntry {
  my ($obj, $directoryUrl) = @_;
  my ($directory)   =   $directoryUrl =~ m{ https? :// [^/]+ ( / .* ) }xms;
  if (!$obj->{robotsTxtLines}) {
    $obj->{robotsTxtLines} = [];
    push @{$obj->{robotsTxtLines}}, 'User-agent: *';
  }
  push @{$obj->{robotsTxtLines}}, "Disallow: $directory";
}
#----------------------------------------------------------------------
sub _saveRobotsTxt {
  my ($obj) = @_;
  open my $FH, '>', $context->getEnv('DOCUMENT_ROOT') . '/robots.txt' or die "Couldn't open robots.txt for writing: $!";
  foreach my $line ( @{$obj->{robotsTxtLines}} ) {
    print {$FH} "$line\n" or die "Couldn't write to file robots.txt";
  }
  close $FH;
  my $autoflush = $context->getSingleton('O2::Gui::Autoflush');
  $autoflush->printLine( $obj->getString('o2.Site.Sitemaps.robotsTxtSaved') );
  $autoflush->printLine();
}
#----------------------------------------------------------------------
sub _getSymbolicUrl {
  my ($obj, $object) = @_;
  my $url = $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(
    object     => $object,
    objectPath => $obj->{path},
    absolute   => 'yes',
  );
  return $url;
}
#----------------------------------------------------------------------
1;
