package O2CMS::Mgr::CategoryManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2CMS::Obj::Category;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Category',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title => { type => 'varchar', multilingual => 1 },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getCategoryByPath {
  my ($obj, $path, $createIfNotExists) = @_;
  my ($currentCategory, $parentId);
  while (@{$path}) {
    my $categoryName = shift @{$path};
    $parentId        = $currentCategory->getId() if $currentCategory;
    ($currentCategory) = $obj->objectSearch(
      metaName     => $categoryName,
      metaParentId => $currentCategory ? $currentCategory->getId() : { isNull => 1 },
      -limit       => 1,
    );
    if (!$currentCategory && $createIfNotExists) {
      die 'Not allowed to create top category' unless $parentId;
      $currentCategory = $obj->newObject();
      $currentCategory->setMetaName(     $categoryName );
      $currentCategory->setMetaParentId( $parentId     );
      $currentCategory->save();
    }
  }
  return $currentCategory;
}
#-------------------------------------------------------------------------------
1;
