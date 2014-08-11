package O2Plugin::Shop::Backend::Gui::Product;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  $obj->_edit(  $context->getObjectById( $obj->getParam('objectId') )  );
}
#---------------------------------------------------------------------------------------------------
sub _getProductMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::ProductManager');
}
#---------------------------------------------------------------------------------------------------
sub _edit {
  my ($obj, $product) = @_;
  $obj->error('Product not found') unless $product;
  $obj->display(
    'edit.html',
    allowIndexing    => $product->getPropertyValue('allowIndexing') eq 'yes' ? 1 : 0,
    product          => $product,
    links            => { $product->getLinks() },
    parentId         => $product->getMetaParentId() ? $product->getMetaParentId() : $obj->getParam('parentId'),
    selectedImageIds => join ( ',', $product->getImageIds() ),
    productTypes     => [ $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->getAvailableProductTypes() ],
  );
}
#---------------------------------------------------------------------------------------------------
sub create {
  my ($obj) = @_;
  my $product            =   $obj->_getProductMgr()->newObject();
  my $defaultProductType = [ $context->getSingleton('O2Plugin::Shop::Mgr::ProductTypeManager')->getAvailableProductTypes() ]->[0];
  $product->setProductTypeId( $defaultProductType->getId() );
  $obj->_edit($product);
}
#---------------------------------------------------------------------------------------------------
sub save {
  my ($obj, $product) = @_;
  
  my %params     = $obj->getParams();
  my $productMgr = $obj->_getProductMgr();
  my $objectId   = delete $params{objectId};
  
  $product ||= $objectId ? $context->getObjectById($objectId) : $productMgr->newObject();
  
  $obj->error('Product not found') unless $product;
  
  # Assigning values to product object
  $product->setProductTypeId(      delete $params{productTypeId} );
  $product->setIsActive(           delete $params{active}        );
  $product->setMetaName(           delete $params{metaName}      );
  $product->setMetaParentId(       delete $params{metaParentId}  );
  $product->setName(               delete $params{name}          );
  $product->setDefaultPriceIncVat( delete $params{priceIncVat}   );
  $product->setSummary(            delete $params{summary}       );
  $product->setDescription(        delete $params{description}   );
  
  # Splitting up the link string
  my @links = split /;/s, delete $params{links};
  shift @links; # Stripping away first element
  
  my %linkHash;
  foreach my $linkPair (@links) {
     my @pair = split /@/s, $linkPair;
     %linkHash->{ $pair[0] } = $pair[1];
  }
  $product->setLinks(%linkHash);
  
  # Images
  my @selectedImages = split /,/s, delete $params{imageIds};
  $product->setImageIds(@selectedImages);
  
  # Additional parameters require prefix productAttribute.
  # NOTE: maximum field length is 255
  $product->setAttributes(); # Delete attributes first.
  foreach my $attributeName ( keys %params ) {
    if ( $attributeName =~ m{ \A productAttribute \. }xms ) {
      $attributeName =~ s{ productAttribute \. }{}xms;
      $product->setAttribute( $attributeName, delete $params{"productAttribute.$attributeName"} );
    }
  }
  
  # Storing product
  $product->save();
  
  # Allow Indexing
  # setPropertyValue does not need to be followed by a save call,
  # but it does require an objectId
  $product->setPropertyValue( 'allowIndexing', $params{allowIndexing} == 1 ?  'yes' : 'no' );

  if ($params{usingSaveFrame}) {
    return $obj->display(
      'o2://var/templates/Universal/savedObject.html',
      object => $product,
      mode   => $objectId ? 'editObject' : 'newObject',
    );
  }
  
  # Back to edit page, so that further editing can be done
  $obj->_edit($product);
}
#---------------------------------------------------------------------------------------------------
1;
