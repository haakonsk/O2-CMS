package O2Plugin::Shop::Obj::Product::Category;

use strict;

use base 'O2CMS::Obj::WebCategory';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub addProduct {
  # Adds a product to this category
  # Is's really just an alias for adding an objectId to
  # childObjectIds
  my ($obj, $objectId) = @_;

  my @childObjectIds = $obj->getChildObjectIds();

  foreach my $childObjectId (@childObjectIds) {
    if ( $childObjectId eq $objectId ) {
      return 1;
    }
  }

  $obj->setChildObjectIds( ($obj->getChildObjectIds(), $objectId) );
  $obj->save();

  return 1;
}
#-----------------------------------------------------------------------------
sub setProducts {
  # Replaces the inlcuded products
  my ($obj, $productIds) = @_;

  my @productsAndCategories;
  my @childrenIds = $obj->getChildObjectIds();
  my @categoryIds;

  foreach my $childId (@childrenIds) {
    my $child = $context->getObjectById($childId);
    push @categoryIds, $childId if $child && !$child->isa('O2Plugin::Shop::Obj::Product');
  }

  @productsAndCategories = (@categoryIds, @{$productIds});

  $obj->setChildObjectIds(@productsAndCategories);
  $obj->save();
  return 1;
}
#-----------------------------------------------------------------------------
sub removeProduct {
  # Removes a product from this category
  # Maybe not quick, but dirty
  my ($obj, $unwantedObjectId) = @_;

  my @currentChildObjectIds = $obj->getChildObjectIds();
  my @updatedChildObjectIds;

  foreach my $childId (@currentChildObjectIds) {
    push @updatedChildObjectIds, $childId unless $childId eq $unwantedObjectId;
  }

  $obj->setChildObjectIds(@updatedChildObjectIds);

  return 1;
}
#-----------------------------------------------------------------------------
sub addSubCategory {
  my ($obj, $objectId) = @_;

  # Make sure we don't add same child all over
  my @subCategoryIds = $obj->getChildObjectIds();
  foreach my $subCategoryId (@subCategoryIds) {
    return 1 if $objectId eq $subCategoryId;
  }
  
  $obj->setChildObjectIds( ($obj->getChildObjectIds(), $objectId) );
  $obj->save();

  return 1;
}
#-----------------------------------------------------------------------------
sub removeSubCategory {
  my ($obj, $unwantedObjectId) = @_;

  my @currentChildObjectIds = $obj->getChildObjectIds();  
  my @updatedChildObjectIds;

  foreach my $childId (@currentChildObjectIds) {
    push @updatedChildObjectIds, $childId unless $childId eq $unwantedObjectId;
  }

  $obj->setChildObjectIds(@updatedChildObjectIds);
  $obj->save();
  return 1;
}
#-----------------------------------------------------------------------------
sub getProducts {
  # Returns an array ref of objects: products
  # I use universalManager to revive objects because
  # the children isn't nessesarily products and because getChildren
  # won't return product objects somehow
  my ($obj, $switch) = @_;

  my @childIds = $obj->getChildObjectIds();

  my @products;
  foreach my $objectId (@childIds) {
    my $object = $context->getObjectById($objectId);
    next if !$object || !$object->isa('O2Plugin::Shop::Obj::Product');
    push @products, $object if $object->isActive();#   &&   ($object->isAvailableFor($membership) || !$object->getAvailableFor())   ||   $switch eq 'override';
  }
  
  return unless @products;

  return \@products;
}
#-----------------------------------------------------------------------------
sub  getSubCategories {
  # Returns an array of objects: categories
  my ($obj) = @_;

  my @childIds = $obj->getChildObjectIds();

  my @categories;
  foreach my $objectId (@childIds) {
    my $category = $context->getObjectById($objectId);
    push @categories, $category if $category->isa('O2Plugin::Shop::Obj::Product::Category');
  }
  
  return unless @categories;
  
  return \@categories;
}
#-----------------------------------------------------------------------------
sub getSubCategories2 {
  # Returns an array of child categories
  my ($obj) = @_;

  my @children = $obj->getChildren();
  my @subCategories;
  foreach my $child (@children) {
    push @subCategories, $child if $child->isa('O2Plugin::Shop::Obj::Product::Category');
  }

  return \@subCategories;
}
#-----------------------------------------------------------------------------
1;
