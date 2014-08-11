package O2CMS::Obj::Desktop;

use strict;

use base 'O2::Obj::Container';

#--------------------------------------------------------------------
sub canRemoveObject {
  my ($obj, $toContainer, $object) = @_;
  return $object->isa('O2CMS::Obj::Desktop::Item');
}
#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2CMS::Obj::Desktop::Item');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1; # can move to anywhere
}
#-------------------------------------------------------------------------------
sub isDeletable {
  my ($obj) = @_;
  return 0;
}
#-------------------------------------------------------------------------------
sub addDesktopItem {
  my ($obj, $item) = @_;
  $obj->addObject($obj, $item);
}
#-------------------------------------------------------------------------------
sub getDesktopItems {
  my ($obj) = @_;
  my @items = $obj->getChildren();
  return wantarray ? @items : \@items;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  my ($obj) = @_;
  return 0;
}
#-------------------------------------------------------------------------------
1;
