use Test::More qw(no_plan);

use strict;

use O2 qw($context);

my ($siteId) = $context->getDbh()->fetch("select min(objectId) from O2_OBJ_OBJECT where className = 'O2CMS::Obj::Site' and status != 'trashed' and status != 'deleted'");

my $articleMgr = $context->getSingleton('O2CMS::Mgr::ArticleManager');
my $article = $articleMgr->newObject();
$article->setMetaName('Test article');
$article->setMetaParentId($siteId);
$article->save();


my $urlMapper = $context->getSingleton('O2CMS::Publisher::UrlMapper');
my $objectId = $article->getId(); # XXX find random object here..
ok($objectId > 0, "Testing with objectId: $objectId");
my $url = $urlMapper->generateUrl(
  object   => $article,
  absolute => 1,
);
ok($url =~ m/http/ && $url !~ m{///}, "Generated proper url: $url");
my $resolvedUrl = $urlMapper->resolveUrl($url);
#ok($resolvedUrl->getMainObjectId()==$objectId, "Url resolved to same objectId: $objectId"); # Guess this method has been renamed..?? Håkon
is($resolvedUrl->getContentObjectId(), $objectId, "Url resolved to same objectId");

sub END {
  $article->deletePermanently() if $article;
}
