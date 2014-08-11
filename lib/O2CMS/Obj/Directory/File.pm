package O2CMS::Obj::Directory::File;

use strict;
use base 'O2::Obj::Object';

#--------------------------------------------------------------------------------------------------
sub setFilename {
  my ($obj, $filename) = @_;
  $obj->setModelValue('filename', $filename);
  $obj->setMetaName($filename);
}
#--------------------------------------------------------------------------------------------------
1;
