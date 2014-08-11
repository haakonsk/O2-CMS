package O2CMS::Obj::Menu;

# Maintains two structures for menuItems internally. one for fast objectId lookup and one for parentId lookup.
# XXX Rewrite to use Model

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  $obj->{data}->{topLevelId}          = undef;
  $obj->{data}->{menuItemsByParentId} = {}; # menuItems organized by parentId
  $obj->{data}->{menuItemsById}       = {}; # menuItems organized by targetId
  return $obj;
}
#-------------------------------------------------------------------------------
sub setTopLevelId {
  my ($obj, $topLevelId) = @_;
  $obj->{data}->{topLevelId} = $topLevelId;
}
#-------------------------------------------------------------------------------
sub getTopLevelId {
  my ($obj) = @_;
  return $obj->{data}->{topLevelId};
}
#-------------------------------------------------------------------------------
# helper method for the templates. Marks all expanded menu items ($menuItem->getExpanded() will return true)
sub setPage {
  my ($obj, $page) = @_;
  foreach my $category ( $page->getCategoryPath() ) {
    my $menuItem = $obj->getMenuItemByObjectId( $category->getId() );
    next unless $menuItem;
    $menuItem->setExpanded(1);
  }
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isMultilingual {
  return 1;
}
#-------------------------------------------------------------------------------
sub getUsedLocales {
  my ($obj) = @_;
  return $obj->getAvailableLocales();
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj) = @_;
#  return 0 if $obj->isDeleted();
  return 1;
}
#-------------------------------------------------------------------------------
sub addMenuItem {
  my ($obj, $menuItem) = @_;
  my $targetId = $menuItem->getTargetId();
  die "TargetId not set" unless $targetId;
  return if $obj->isMenuItemAdded($targetId); # menuItem already added to menu

  my $parentId = $menuItem->getParentId();
  die "ParentId not set" unless $parentId;
  # place at bottom of menu, if position not set
  if ( !defined $menuItem->getPosition() ) {
    my $itemsAtLevel = $obj->{data}->{menuItemsByParentId}->{$parentId} || [];
    $menuItem->setPosition(scalar @{$itemsAtLevel});
  }

  # add menuItem to both structures
  push @{ $obj->{data}->{menuItemsByParentId}->{$parentId} }, $menuItem; # no need to sort here, since position depends on locale
  $obj->{data}->{menuItemsById}->{$targetId} = $menuItem;
}
#-------------------------------------------------------------------------------
sub removeMenuItemById {
  my ($obj, $objectId) = @_;
  
  my $menuItem = $obj->getMenuItemByObjectId($objectId);
  # remove menu item from parent lookup
  my @folderItems = @{  $obj->{data}->{menuItemsByParentId}->{ $menuItem->getParentId() }  };
  @folderItems = grep { $_->getTargetId() != $menuItem->getTargetId() } @folderItems;
  $obj->{data}->{menuItemsByParentId}->{ $menuItem->getParentId() } = \@folderItems;
  # remove menu item from objectId lookup
  delete $obj->{data}->{menuItemsById}->{ $menuItem->getTargetId() };
}
#-------------------------------------------------------------------------------
# returns true if $targetId is already added
sub isMenuItemAdded {
  my ($obj, $targetId) = @_;
  return exists $obj->{data}->{menuItemsById}->{$targetId};
}
#-------------------------------------------------------------------------------
sub clearMenuItems {
  my ($obj) = @_;
  $obj->{data}->{menuItemsByParentId} = {};
  $obj->{data}->{menuItemsById}       = {};
}
#-------------------------------------------------------------------------------
# returns menuItem with $targetId, or new menuItem
sub getMenuItemByObjectId {
  my ($obj, $targetId) = @_;
  return $obj->{data}->{menuItemsById}->{$targetId} if $obj->isMenuItemAdded($targetId);
  my $menuItem = O2CMS::Obj::Menu::MenuItem->new(menu => $obj);
  $menuItem->setTargetId($targetId);
  return $menuItem;
}
#-------------------------------------------------------------------------------
sub getMenuItems {
  my ($obj) = @_;
  my $items = [];
  $obj->_getMenuItems( $obj->getTopLevelId(), $items );
  return @{$items};
}
#-------------------------------------------------------------------------------
# gather menuitems in hierarchical order
sub _getMenuItems {
  my ($obj, $parentId, $items) = @_;
  my @newItems = $obj->getMenuItemsAt($parentId);
  push @{$items}, @newItems;
  my $position = 0;
  foreach my $item (@newItems) {
    $item->setPosition($position++); # make sure positions are sequential
    $obj->_getMenuItems( $item->getTargetId(), $items );
  }
}
#-------------------------------------------------------------------------------
sub getMenuItemsAt {
  my ($obj, $parentId) = @_;
  my $items = $obj->{data}->{menuItemsByParentId}->{$parentId}; # XXX sort depending on locale
  return unless $items;
  return sort { ($a->getPosition() || 0) <=> ($b->getPosition() || 0) } @{$items};
}
#-------------------------------------------------------------------------------
sub getNumberOfMenuItemsAt {
  my ($obj, $targetId) = @_;
  my @items = $obj->getMenuItemsAt($targetId);
  return 0 unless @items;
  return scalar @items;
}
#-------------------------------------------------------------------------------
sub includeNewMenuItems {
  my ($obj) = @_;
  my $object = $context->getObjectById( $obj->getTopLevelId() ); # scan from top-level
  $obj->{manager}->includeNewMenuItems( $obj, $object, $object->getMetaParentId() );
}
#-------------------------------------------------------------------------------
sub getMenuItemUrl {
  my ($obj, $targetId) = @_;
  
  # find parent objects as far back as the menu knows about
  my @objectPath;
  my $objectId = $targetId;
  while ( $obj->isMenuItemAdded($targetId) ) {
    my $menuItem = $obj->getMenuItemByObjectId($targetId);
    push @objectPath, $menuItem->getTarget();
    $targetId = $menuItem->getParentId();
  }
  # generate url based on object path in menu
  return $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(
    object     => $context->getObjectById($objectId),
    objectPath => [ reverse @objectPath ],
  );
}
#-------------------------------------------------------------------------------
sub asString {
  my ($obj) = @_;
  return join '', map { $_->asString() . "\n" } $obj->getMenuItems();
}
#-------------------------------------------------------------------------------
sub asTreeString {
  my ($obj, $levelId, $indent) = @_;
  $levelId = $obj->getTopLevelId() unless $levelId;
  my $text = '';
  foreach my $item ($obj->getMenuItemsAt($levelId)) {
    $text .= '-' x ($indent+1);
    $text .= '[' . $item->getTargetId() . ']' . $item->getTargetName() . " (pos:" . $item->getPosition() . ")\n";
    $text .= $obj->asTreeString( $item->getTargetId(), $indent+1 );
  }
  return $text;
}
#-------------------------------------------------------------------------------
sub getContentPlds {
  my ($obj) = @_;
    
  my @menuItems;
    
  foreach my $parentId (sort keys %{ $obj->{data}->{menuItemsByParentId} }) {
    foreach my $menuItem (@{ $obj->{data}->{menuItemsByParentId}->{$parentId} }) {
      push @menuItems, $menuItem->getObjectPlds();
    }
  }
  my $data = {
    topLevelId => $obj->getTopLevelId,
    menuItems  => \@menuItems,
  };
  return $data;
}
#-------------------------------------------------------------------------------
sub setContentPlds { # Usually inherited
  my ($obj, $plds) = @_;
  
  if ($obj->verifyContentPlds($plds)) {
    my $menuItems = delete $plds->{menuItems};
    foreach my $menuItemData (@{$menuItems} ) {
      my $menuItem = O2CMS::Obj::Menu::MenuItem->new(menu => $obj);
      $menuItem->{data} = $menuItemData->{data};
      $obj->addMenuItem($menuItem);
    }
    $obj->setTopLevelId( $plds->{topLevelId} );
  }
  else {
    die "ContentPLDS could not be verified: $@";
  }
  return 1;
}
#-------------------------------------------------------------------------------
1;
