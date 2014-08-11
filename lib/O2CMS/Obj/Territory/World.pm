package O2CMS::Obj::Territory::World;

use strict;

use base 'O2CMS::Obj::Territory';

use O2 qw($context);

#-------------------------------------------------------------------------------
# return localized name
sub getName {
  my ($obj) = @_;
  return $context->getLocale()->getTerritoryName( $obj->getCode() );
}
#-------------------------------------------------------------------------------
1;
