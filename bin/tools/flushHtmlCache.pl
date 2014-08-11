#!/usr/bin/perl
# flush all cached frontpages and articles
use strict;

use O2::Util::SetApacheEnv;

use O2 qw($context $config);
my $htmlPath = $config->get('o2.documentRoot');

my $cachePath = $context->getSitePath() . '/var/cache/pagecache';
die "Could not find cachePath, I tried '$cachePath'" unless -d $cachePath;

print "Documentroot: $htmlPath\n";
print "CachePath   : $cachePath\n";

# Find all html files that are cached.
print "Running: grep -R 'O2 Cached at:' $htmlPath -l\n";
my @htmlFiles = `grep -R 'O2 Cached at:' $htmlPath -l`;
print 'Found ' . @htmlFiles . " files to delete\n";
foreach my $file (@htmlFiles) {
  chomp $file;
  print "Deleting: $file\n";
  unlink $file;
}

# Deleting all PLDS Files
print "Deleting PLDS files\n";
if (-d $cachePath) {
  print "Running: find $cachePath -name '*.plds'\n";
  my @pldsFiles = `find $cachePath -name '*.plds'`;
  print 'Found ' . @pldsFiles . " files to delete\n";
  foreach my $file (@pldsFiles) {
    chomp $file;
    print "Deleting: $file\n";
    unlink $file;
  } 
}
