package O2CMS::Obj::Territory::PostalPlace;

use strict;
use base 'O2CMS::Obj::Territory';

#-------------------------------------------------------------------------------
sub getName {
  my ($obj) = @_;
  if ( $obj->getCodePath() =~ m/^001::150::154::NO::/ ) { # norwegian postal place
    return $obj->getCode() . ' ' . $obj->getMetaName();
  }
  die 'Only know how to format norwegain postal codes';
}
#-------------------------------------------------------------------------------
1;
