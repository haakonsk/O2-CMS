package O2CMS::Mgr::FrontpageManager;

use strict;

use base 'O2CMS::Mgr::PageManager';

use O2 qw($context);
use O2CMS::Obj::Frontpage;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Frontpage',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getFrontpageIdByCategoryId {
  my ($obj, $categoryId) = @_;
  my ($objectId) = $obj->objectIdSearch(
    metaParentId => $categoryId,
    -isa         => 'O2CMS::Obj::Frontpage',
  );
  return $objectId;
}
#-------------------------------------------------------------------------------
sub getFrontpageByCategoryId {
  my ($obj, $categoryId) = @_;
  my $frontpageId = $obj->getFrontpageIdByCategoryId($categoryId) or return;
  return $context->getObjectById($frontpageId);
}
#-------------------------------------------------------------------------------
1;
