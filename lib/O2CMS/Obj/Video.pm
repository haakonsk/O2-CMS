package O2CMS::Obj::Video;

# Class representing a video file

use strict;
use base 'O2::Obj::File';

#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1; # can move to anywhere
}
#-------------------------------------------------------------------------------
1;
