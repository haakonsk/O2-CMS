package O2CMS::Obj::Category::Keywords;

# Class representing the category for keywords

use strict;
use base 'O2CMS::Obj::Category';

#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2::Obj::Keyword');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0; # can not move
}
#-------------------------------------------------------------------------------
1;
