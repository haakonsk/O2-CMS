package O2CMS::Publisher::Media::SlotTagExtractor;

# Dummy media for extractng information about <o2 slot> tags in a template

use strict;

use base 'O2CMS::Publisher::Media::Html'; # should act exactly like O2CMS::Publisher::Media::Html

#------------------------------------------------------------------
sub new {
  my ($package, %init) = @_;
  my $obj = $package->SUPER::new(%init);
  $obj->{slotTags} = {};
  return $obj;
}
#------------------------------------------------------------------
# returns html for a slot including header control panel
sub renderSlot {
  my ($obj, %params) = @_;
  $obj->{slotTags}->{ $params{slotId} } = { %params };
  return $obj->SUPER::renderSlot(%params);
}
#------------------------------------------------------------------
1;
