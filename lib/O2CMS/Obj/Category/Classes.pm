package O2CMS::Obj::Category::Classes;

# Class representing the category for classes

use strict;
use base 'O2CMS::Obj::Category';

#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2::Obj::Class');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0; # can not move
}
#-------------------------------------------------------------------------------
1;
