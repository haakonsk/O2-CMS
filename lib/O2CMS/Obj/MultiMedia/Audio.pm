package O2CMS::Obj::MultiMedia::Audio;

use strict;
use base 'O2::Obj::File';

sub isSerializable {
  shift; return 0;
}
1;
