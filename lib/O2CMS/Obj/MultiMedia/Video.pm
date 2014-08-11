package O2CMS::Obj::MultiMedia::Video;

use strict;
use base 'O2::Obj::File';

sub isSerializable {
  shift; return 0;
}
1;
