use strict;

use O2 qw($context);

my $topCategoryId = $ARGV[0];
my $oldTemplateId = $ARGV[1];
my $newTemplateId = $ARGV[2] or die "usage: $0 topCategoryId oldTemplateId newTemplateId";

my $topObject = $context->getSingleton('O2::Mgr::UniversalManager')->getObjectById($topCategoryId);
changeFrontpageTemplates($topObject);

sub changeFrontpageTemplates {
  my ($category) = @_;
  foreach my $object ($category->getChildren()) {
    if ($object->isa('O2CMS::Obj::Frontpage')) {
      if ($object->getTemplateId() == $oldTemplateId) {
        print $category->getUrl(), ": change templateId from ", $object->getTemplateId(), " for ", $object->getMetaName(), "\n";
        $object->setTemplateId($newTemplateId);
#        $object->save();
      }
      else {
        print "\t", $category->getUrl(), " ", $object->getTemplateId(), "\n";
      }
    }
    changeFrontpageTemplates($object) if $object->isa('O2CMS::Obj::WebCategory');
  }
}
