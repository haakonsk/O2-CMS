package O2CMS::Backend::Gui::Widget;

use strict;

use base 'O2CMS::Backend::Gui';

#------------------------------------------------------------------
sub delete {
  my ($obj, $objectId) = @_;
  return 1;
}
#------------------------------------------------------------------
sub deletePermanently {
  my ($obj, $objectId) = @_;
  return 1;
}
#------------------------------------------------------------------
1;
