use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';

my $context = O2::Context->new();
ok($context, 'context');

use_ok 'O2CMS::Mgr::Feed::RssManager';

my $url = "file://$ENV{O2ROOT}/t/data/test.rss";
my $rssMgr = $context->getSingleton('O2CMS::Mgr::Feed::RssManager');
my $rss = $rssMgr->newObject();
$rss->setUrl($url);
$rss->setMetaName('Test rss feed');
$rss->save();
ok($rss->getId()>0, 'save()');


my $rss2 = $rssMgr->getObjectById( $rss->getId() );
#$rss2->refresh();

# test rss channel elements
is( $rss2->getChannelTitle(),       'channelTitle',       'getChannelTitle()'       );
is( $rss2->getChannelLink(),        'channelLink',        'getChannelLink()'        );
is( $rss2->getChannelDescription(), 'channelDescription', 'getChannelDescription()' );
# test rss image
ok( $rss2->hasImage(), 'hasImage()');
is( $rss2->getImageTitle(), 'imageTitle', 'getImageTitle()' );
is( $rss2->getImageUrl(),   'imageUrl',   'getImageUrl()'   );
is( $rss2->getImageLink(),  'imageLink',  'getImageLink()'  );

# test items
my @items = $rss2->getItems();
foreach my $number (1..2) {
  my $item = $items[$number-1];
  is( $item->getTitle(),       "title$number",       '$item->getTitle()'       );
  is( $item->getLink(),        "link$number",        '$item->getLink'          );
  is( $item->getDescription(), "description$number", '$item->getDescription()' );
}


# test status/error codes
my @statusTests = (
  { url => $url,                                    status => 'ok'               }, # feed url should give status ok
  { url => '',                                      status => 'errorDownloading' }, # empty url should fail to download
  { url => "file:///$ENV{O2ROOT}/etc/conf/o2.conf", status => 'errorParsing'     }, # o2.conf should fail to parse
);
foreach my $test (@statusTests) {
  $rss->setUrl( $test->{url} );
  $rss->refresh();
  is( $rss->getStatus(), $test->{status}, "getStatus() $test->{status}" );
}

END {
  $rss->deletePermanently();
}
