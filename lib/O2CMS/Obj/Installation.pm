package O2CMS::Obj::Installation;

use strict;

use base 'O2::Obj::Container';

#-------------------------------------------------------------------------------
sub isDeletable {
  return 0;
}
#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2CMS::Obj::Site');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0; # can not move
}
#-------------------------------------------------------------------------------
sub canRemoveObject {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1;
}
#-------------------------------------------------------------------------------
1;
