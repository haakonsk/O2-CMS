use Test::More qw(no_plan);

use O2 qw($context);

my $trashcan = $context->getSingleton('O2CMS::Mgr::TrashcanManager')->newObject();
$trashcan->setMetaName('Test trashcan');
$trashcan->save();
ok($trashcan->getId()>0, 'save()');

# --- When we delete a container, all children should be deleted recursively ---
my ($category, $subCategory) = createCategorWithSubcategory();

# trash first category
$trashcan->addObject(undef, $category);

# both categories were deleted?
ok(!$context->getObjectById($category->getId()),    'Added object deleted');
ok(!$context->getObjectById($subCategory->getId()), 'Added object recursively deleted');

# getChildren returns only category?
is_deeply([map {$_->getId()} $trashcan->getChildren()], [$category->getId()], 'getChildren()');
# cleanup

sub createCategorWithSubcategory {
  my $categoryMgr = $context->getSingleton('O2CMS::Mgr::CategoryManager');
  my $category = $categoryMgr->newObject();
  $category->setMetaName('Category');
  $category->setMetaParentId(1234567890);
  $category->save();
  
  my $subCategory = $categoryMgr->newObject();
  $subCategory->setMetaParentId( $category->getId() );
  $subCategory->setMetaName(     'Subcategory'      );
  $subCategory->save();
  
  ok( $category->getId() > 0 && $subCategory->getId() > 0, 'Test data created' );
  
  return ($category, $subCategory);
}

END {
  $category->deletePermanently( recursive => 1 ) if $category;
  $trashcan->deletePermanently()                 if $trashcan;
}
