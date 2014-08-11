use strict;

use Test::More qw(no_plan);
use_ok 'O2::Cgi';
use_ok 'O2::Context';
use_ok 'O2CMS::Mgr::PageManager';
use_ok 'O2CMS::Obj::Template::Slot';
my $context = O2::Context->new(cgi => O2::Cgi->new(tieStdout => 'no'));
my @locales = @{ $context->getConfig()->get('o2.locales') };

my $pageMgr = $context->getSingleton('O2CMS::Mgr::PageManager');
my $page = $pageMgr->newObject();
$page->setMetaName('Page test');
foreach my $locale (@locales) {
  $page->setCurrentLocale($locale);
  $page->setTitle('Page title '.$locale);
}      
my $template = getPageTemplate($context);
ok($template && $template->getId()>0, 'Page template found');
$page->setTemplateId($template->getId());

my %slots = (
  'right' => {
    'override' => {'username'=>'arne.vonheim', 'imageId'=>37},
    'templateId' => 2,
    'contentId' => 37,
  },
  'left' => {
    'override' => {'username'=>'gunnar.nilsen', 'imageId'=>82},
    'templateId' => 63,
    'contentId' => 91,
  },
);

foreach my $slotId (keys %slots) {
    my $slot = O2CMS::Obj::Template::Slot->new();
    $slot->setSlotId(     $slotId                       );
    $slot->setContentId(  $slots{$slotId}->{contentId}  );
    $slot->setTemplateId( $slots{$slotId}->{templateId} );
    $slot->setOverride(%{ $slots{$slotId}->{override}}  );
    $page->setSlot($slot);
}
$page->save();
ok($page->getId()>0, 'Page saved');

my $dbPage = $pageMgr->getObjectById($page->getId());
ok($dbPage->getId()==$page->getId(), 'DB page has identical id');
ok($dbPage->getMetaName() eq $page->getMetaName(), 'DB page has identical name');
foreach my $locale (@locales) {
  $page->setCurrentLocale($locale);
  $dbPage->setCurrentLocale($locale);
  ok($dbPage->getTitle() eq $page->getTitle(), "DB page has identical $locale title. " . $dbPage->getTitle() . " == " . $page->getTitle());
}
is_deeply($dbPage->getContentPlds(), $page->getContentPlds(), 'DB page has identical slots');

my $slotList = $page->getSlotListWithTags();

my @standardPageIds = (2,3,4);
$pageMgr->setCategoryStandardPageIds(1, @standardPageIds);
is_deeply( \@standardPageIds, [$pageMgr->getCategoryStandardPageIds(1)], 'getCategoryStandardPageIds()');
$pageMgr->setCategoryStandardPageIds(1); # clean up db again

# ensure /Templates/Pages/frontpage.html has been discovered, and return it
sub getPageTemplate {
  my ($context) = @_;
  use O2::Mgr::MetaTreeManager;
  my $metaTreeMgr = O2::Mgr::MetaTreeManager->new(context=>$context);
  my $templates = $metaTreeMgr->getObjectByPath('/Templates');
  $templates->getChildren();
  my $pages = $metaTreeMgr->getObjectByPath('/Templates/Pages');
  $pages->getChildren();
  return $metaTreeMgr->getObjectByPath('/Templates/Pages/frontpage.html');
}

END {
  $page->deletePermanently();
}
