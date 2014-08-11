use strict;

use Test::More qw(no_plan);

use O2 qw($context $config);

my @locales = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2CMS::Mgr::UrlManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2CMS::Obj::Url/O2CMS::Mgr::UrlManager');
foreach my $locale (@locales) {
  $newObj->setCurrentLocale($locale);
  $newObj->setTitle('Test-varchar');
}
$newObj->setUrl('http://www.redpill-linpro.com');
$newObj->setNewWindow(1);
$newObj->setAttribute( 'a', 1      ),
$newObj->setAttribute( 'b', [0, 1] );
$newObj->save();

ok($newObj->getId() > 0, 'Object saved ok');

my $dbObj = $context->getObjectById( $newObj->getId() );
is( $dbObj->getMetaName(),  $newObj->getMetaName(),  'title retrieved ok'     );
is( $dbObj->getUrl(),       $newObj->getUrl(),       'url retrieved ok'       );
is( $dbObj->getNewWindow(), $newObj->getNewWindow(), 'newWindow retrieved ok' );
foreach my $locale (@locales) {
  $newObj->setCurrentLocale($locale);
  is($dbObj->getTitle(), $newObj->getTitle(), 'title retrieved ok.');
}
is(        $dbObj->getAttribute('a'), $newObj->getAttribute('a'), 'a attribute retrieved ok' );
is_deeply( $dbObj->getAttribute('b'), $newObj->getAttribute('b'), 'b attribute retrieved ok' );

END {
  $newObj->deletePermanently() if $newObj;
}

