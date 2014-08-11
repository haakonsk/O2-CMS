use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';
my $context = O2::Context->new();
use_ok 'O2CMS::Mgr::CategoryManager';

my $categoryMgr = $context->getSingleton('O2CMS::Mgr::CategoryManager');
my $category = $categoryMgr->newObject();
$category->setMetaName('Test category');
my @locales = ($category->getCurrentLocale(), 'fakeLocale');
foreach my $locale (@locales) {
  $category->setCurrentLocale($locale);
  $category->setTitle("Title $locale");
}
$category->save();
ok($category->getId()>0, 'Category saved');

my $category2 = $categoryMgr->getObjectById($category->getId());
ok($category->getId()==$category2->getId(), 'Category loaded');
foreach my $locale (@locales) {
  $category->setCurrentLocale($locale);
  ok($category->getTitle() eq "Title $locale", "getTitle() $locale");
}

$category->deletePermanently( recursive => 1 );
