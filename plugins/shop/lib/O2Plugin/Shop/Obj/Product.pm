package O2Plugin::Shop::Obj::Product;

use strict;

use base 'O2::Obj::Object';
use base 'O2::Role::Obj::Attributes';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub setDefaultPriceIncVat {
  my ($obj, $priceIncVat) = @_;
  $obj->setDefaultPriceExVat( $obj->excludeVat($priceIncVat) ) if $obj->getProductTypeId();
  $obj->setPriceIncVat($priceIncVat);
}
#-----------------------------------------------------------------------------
sub getDefaultPriceIncVat {
  my ($obj) = @_;
  return $obj->includeVat( $obj->getDefaultPriceExVat() ) if $obj->getProductTypeId();
  return $obj->getModelValue('priceIncVat'); # if we don't have a product type, we have to assume this field has what we need
}
#-----------------------------------------------------------------------------
sub getPriceExVat {
  my ($obj) = @_;
  my $priceExVat = $obj->getDefaultPriceExVat();
  foreach my $variantOption ($obj->getVariantOptions()) {
    $priceExVat = $variantOption->getModifiedPriceExVat($priceExVat);
  }
  return $priceExVat;
}
#-----------------------------------------------------------------------------
sub getPriceIncVat {
  my ($obj) = @_;
  return $obj->includeVat( $obj->getPriceExVat() ) if $obj->getProductTypeId();
  return $obj->getModelValue('priceIncVat'); # if we don't have a product type, we have to assume this field has what we need
}
#-----------------------------------------------------------------------------
sub excludeVat {
  my ($obj, $priceIncVat) = @_;
  return $priceIncVat  /  (1 + $obj->getVatPercentage()/100);
}
#-----------------------------------------------------------------------------
sub includeVat {
  my ($obj, $priceExVat) = @_;
  return $priceExVat  *  (1 + $obj->getVatPercentage()/100);
}
#-----------------------------------------------------------------------------
sub getVatPercentage {
  my ($obj) = @_;
  my $productType = $obj->getProductType();
  return $productType->getVatPercentage() if $productType;
  return undef;
}
#-----------------------------------------------------------------------------
sub getProductType {
  my ($obj) = @_;
  
  my $productTypeId = $obj->getProductTypeId();
  my $productType;
  $productType = $context->getObjectById($productTypeId) if $productTypeId;
  
  if ($productType && !$productType->isa('O2Plugin::Shop::Obj::ProductType') ) {
    die "$productTypeId is not a valid product type for product '" . $obj->getId() . "'. It's of type " . ref $productType;
  }
  
  return $productType;
}
#-----------------------------------------------------------------------------
sub setName {
  my ($obj, $name) = @_;
  $obj->setModelValue('name', $name);
  $obj->setMetaName($name) if $obj->getCurrentLocale() eq $context->getLocaleCode();
}
#-----------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $id ($obj->getVariantOptionIds()) {
    my $variantOption = $context->getObjectById($id);
    $variantOption->deletePermanently() if $variantOption;
  }
  $obj->SUPER::deletePermanently();
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;

  # Storing object
  $obj->SUPER::save();

  require O2CMS::Search::ObjectIndexer;
  my $objIndexer = O2CMS::Search::ObjectIndexer->new(
    indexName => 'O2_SHOP_PRODUCT',
    -debug    => 0,
  );

  if ( $obj->getPropertyValue('allowIndexing') eq 'yes' ) {
    # Allows indexing on this object
    
    # Add product to index
    
    # Convert some encodings - FAM
    my $name        = $obj->getName();
    my $description = $obj->getDescription();
    my $summary     = $obj->getSummary();

    $objIndexer->addOrUpdateObject( 
      $obj,
      attributes => {
        name        => $name,
        description => $description,
        summary     => $summary,
      },
    );
    
    # We want to do this later in the import script - FAM
    #$objIndexer->index();
  }
  else {
    # Remove this from the index
    $objIndexer->removeObject($obj);
  }
  # And we are done
}
#-----------------------------------------------------------------------------
sub getImages {
  # Returns all images connected to this product
  my ($obj) = @_;
  my @imageIds = $obj->getImageIds();
  my @images = $context->getObjectsByIds(@imageIds);
  return @images;
}
#-----------------------------------------------------------------------------
sub getVariants {
  # Returns all variants assigned to this product
  my ($obj) = @_;
  my @variantIds = $obj->getVariantIds();
  my @variants = $context->getObjectsByIds(@variantIds);
  return @variants;
}
#-----------------------------------------------------------------------------
sub getAssociatedProducts {
  # Returns all products associated with this product
  my ($obj) = @_;

  my @associatedProductIds = $obj->getAssociatedProductIds();
  my @associatedProducts = $context->getObjectsByIds(@associatedProductIds);

  return @associatedProducts;
}
#-----------------------------------------------------------------------------
sub associateProduct {
  # Adds a productId to the list of associatedProductIds
  my ($obj, $productId) = @_;
  
  my @associatedProductIds = $obj->getAssociatedProductIds();
  
  # Do not add existing id
  use O2::Util::List qw(upush);
  upush @associatedProductIds, $productId;
  
  $obj->setAssociatedProductIds(@associatedProductIds);
}
#-----------------------------------------------------------------------------
sub getIncludedProducts {
  # Returns all included products
  my ($obj) = @_;

  my @includedProductIds = $obj->getIncludedProductIds();
  my @includedProducts = $context->getObjectsByIds(@includedProductIds);

  return @includedProducts;
}
#-----------------------------------------------------------------------------
sub includeProduct {
  # Adds a productId to the list of includedProductIds
  my ($obj, $productId) = @_;
  
  my @includedProductIds = ( $obj->getIncludedProductIds(), $productId );
  $context->setIncludedProductIds(\@includedProductIds);
}
#-----------------------------------------------------------------------------
sub isAvailableInPeriod {
  my ($obj, $fromDate, $toDate) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLine::ReservationManager')->productIsAvailableInPeriod( $obj->getId(), $fromDate, $toDate );
}
#-----------------------------------------------------------------------------
sub canMove {
  return 1;
}
#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getIndexableFields {
  my ($obj) = @_;
  return ($obj->SUPER::getIndexableFields(), qw(name summary description));
}
#-----------------------------------------------------------------------------
1;
