package O2CMS::Obj::Url;

use strict;

use base 'O2::Obj::Object';
use base 'O2::Role::Obj::Attributes';

#-----------------------------------------------------------------------------
sub canMove {
  return 1;
}
#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getTitle {
  my ($obj) = @_;
  return $obj->getModelValue('title') || $obj->getMetaName();
}
#-----------------------------------------------------------------------------
1;
