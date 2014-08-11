package O2CMS::Mgr::KeywordManager;

use strict;

use base 'O2::Mgr::KeywordManager';

use O2 qw($context);

#--------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  unless ($object->getMetaParentId() > 0) {
    my ($keywordCategory) = $context->getSingleton('O2CMS::Mgr::Category::KeywordsManager')->objectSearch(-limit => 1);
    $object->setMetaParentId( $keywordCategory->getId() ) if $keywordCategory;
  }
  $obj->SUPER::save($object);
}
#--------------------------------------------------------------------------------
1;
