package O2CMS::Role::Obj::Page;

use strict;

use O2 qw($context);

#-------------------------------------------------------------------------------
sub getSlotListWithTags {
  my ($obj) = @_;
  my $slotList = $obj->getSlotList();
  if (!$slotList->areSlotTagsLoaded()) {
    $context->getSingleton('O2CMS::Mgr::Template::SlotManager')->addTagsToSlotList( $slotList, $obj->getId() );
  }
  return $slotList;
}
#-------------------------------------------------------------------------------
sub unpublishFromSlot {
  my ($obj, $slotId) = @_;
  my $slotList = $obj->getSlotListWithTags();
  $slotList->clearSlot($slotId);
  $slotList->getManager()->saveSlotList( $obj->getId(), $slotList );
}
#-------------------------------------------------------------------------------
1;
