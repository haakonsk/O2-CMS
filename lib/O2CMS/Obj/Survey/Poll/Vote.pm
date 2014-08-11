package O2CMS::Obj::Survey::Poll::Vote;

use strict;
use base 'O2::Obj::Object';

#-----------------------------------------------------------------------------
sub isSerializable {
  return 0; # Don't want revisions to be saved for votes, I guess.
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

1;
