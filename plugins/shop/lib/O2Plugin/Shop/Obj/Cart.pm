package O2Plugin::Shop::Obj::Cart;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#--------------------------------------------------------------------
sub addItem {
  # This function will add one product to the cart
  # This function is different as it is takes a product ID
  # and not an item ID. It will create an item object and make
  # the nessesary connections.
  # Will fail if the variant is not connected to the product and so on...
  my ($obj, $productId, $amount, $variantOptionIds) = @_;

  my $product = $context->getObjectById($productId);
  die "Not a product" unless $product->isa( 'O2Plugin::Shop::Obj::Product' );

  foreach my $variantId ( keys %{$variantOptionIds} ) {
    my $variant = $context->getObjectById($variantId);
    die "Not a variant" unless $variant->isa('O2Plugin::Shop::Obj::Product::Variant');

    my $option = $context->getObjectById( $variantOptionIds->{$variantId} );
    die "Not an option" unless $option->isa('O2Plugin::Shop::Obj::Product::Variant::Option');
  }

  my $item = $context->getSingleton('O2Plugin::Shop::Mgr::Cart::ItemManager')->newObject();
  $item->setMetaName(         'cartItem'           );
  $item->setProductId(        $product->getId()    );
  $item->setAmount(           $amount              );
  $item->setVariantOptionIds( %{$variantOptionIds} );
  $item->save();

  $obj->setItemIds( $obj->getItemIds(), $item->getId() );
  $obj->save();

  return 1;
}
#--------------------------------------------------------------------
sub removeItem {
  # This function will remove an item from the cart.
  # It will also delete the item object - also, it will return false if the
  # item is not associated with this cart.
  my ($obj, $unwantedItemId) = @_;
  
  my @itemIds = $obj->getItemIds();

  my $found = grep /$unwantedItemId/, @itemIds;
  return 0 unless $found;

  my $item = $context->getObjectById($unwantedItemId);
  $item->deletePermanently();

  my @updatedItemIds;
  foreach my $itemId (@itemIds) {
    push @updatedItemIds, $itemId if $itemId ne $unwantedItemId;
  }

  $obj->setItemIds(@updatedItemIds);
  $obj->save();

  return 1;
}
#--------------------------------------------------------------------
sub updateAmount {
  # This function will update the sum of a selected product
  # If the value of a product is set to zero, the product is removed.
  # Will return false (0) if item is not assigned to this cart.
  my ($obj, $itemId, $amount) = @_;
  
  my @itemIds = $obj->getItemIds();

  my $found = grep /$itemId/, @itemIds;
  return 0 unless $found;

  my $item = $context->getObjectById($itemId);
  $item->setAmount($amount);
  $item->save();
  return 1;
}
#--------------------------------------------------------------------
sub countProducts {
  # This function will count the number of products in the cart
  # and then return a sum of all products.
  # Extracts all items and for each item it reads the amount variable
  my ($obj) = @_;

  my @itemIds = $obj->getItemIds();

  my $totalProducts = 0;
  foreach my $itemId (@itemIds) {
    my $item = $context->getObjectById($itemId);
    $totalProducts += $item->getAmount();
  }

  return $totalProducts;
}
#--------------------------------------------------------------------
sub getTotalIncVat {
  # This will query all products in the basket and collect the total inc vat
  my ($obj) = @_;
  
  my @itemIds = $obj->getItemIds();

  my $totalIncVat = 0;
  foreach my $itemId (@itemIds) {
    my $item      = $context->getObjectById($itemId);
    my $amount    = $item->getAmount();
    my $productId = $item->getProductId();
    my $product   = $context->getObjectById($productId);
    $totalIncVat += $amount * $product->getPriceIncVat();
  }
  return $totalIncVat;
}
#--------------------------------------------------------------------
sub getTotalExVat {
  # This will query all products in the basket and collect the total ex vat
  my ($obj) = @_;
  
  my @itemIds = $obj->getItemIds();

  my $totalExVat = 0;
  foreach my $itemId (@itemIds) {
    my $item      = $context->getObjectById($itemId);
    my $amount    = $item->getAmount();
    my $productId = $item->getProductId();
    my $product   = $context->getObjectById($productId);
    $totalExVat += $amount * $product->getPriceExVat();
  }
  return $totalExVat;
}
#--------------------------------------------------------------------
sub clear {
  # Empties the cart
  # Deletes all connected item objects and clears the itemIds array
  my ($obj) = @_;

  my @itemIds = $obj->getItemIds();
  foreach my $itemId (@itemIds) {
    my $item = $context->getObjectById($itemId);
    $item->deletePermanently();
  }
  $obj->setItemIds();
  $obj->save();
}
#--------------------------------------------------------------------
sub getItems {
  # Returns an array of item objects
  my ($obj) = @_;

  my @itemIds = $obj->getItemIds();
  
  my @items;
  foreach my $itemId (@itemIds) {
    my $item = $context->getObjectById($itemId);
    push @items, $item;
  }
  
  return \@items;
}
#--------------------------------------------------------------------
sub isCachable {
  return 0;
}
#--------------------------------------------------------------------
sub containsProduct {
  my ($obj, $product) = @_;
  my @items = @{ $obj->getItems() };
  foreach my $item (@items) {
    return 1 if $item->getProductId() == $product->getId();
  }
  return 0;
}
#--------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  foreach my $item (@{ $obj->getItems() }) {
    $item->delete();
  }
}
#--------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  foreach my $item (@{ $obj->getItems() }) {
    $item->deletePermanently();
  }
}
#--------------------------------------------------------------------
1;
