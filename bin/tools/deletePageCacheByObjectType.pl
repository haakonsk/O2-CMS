use strict;

use O2::Context;
my $context = O2::Context->new();

use O2::Util::Args::Simple;
my $class   = $ARGV{class} or die 'Need "class" parameter';
my $verbose = $ARGV{v} || 0;

my $pageCache = $context->getSingleton('O2::Publisher::PageCache');
my @ids = $pageCache->_findAllCachedPages($class);
print scalar (@ids) . " cached objects to delete\n" if $verbose;

foreach my $id (@ids) {
  print "Deleting $id\n" if $verbose;
  $pageCache->delCacheById($id);
}
