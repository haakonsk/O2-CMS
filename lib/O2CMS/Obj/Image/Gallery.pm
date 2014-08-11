package O2CMS::Obj::Image::Gallery;

use strict;
use base 'O2::Obj::Object';

#-------------------------------------------------------------------------------
sub getRandomId {
  my ($obj) = @_;
  my @imageIds = $obj->getImageIds();
  return $imageIds[int rand @imageIds];
}
#-------------------------------------------------------------------------------
1;
