package O2CMS::Mgr::Template::SlotManager;

# Manager for O2CMS::Obj::Template::Slot and O2CMS::Obj::Template::SlotList (not proper O2 objects)

use strict;

use O2 qw($context $db);
use O2CMS::Obj::Template::Slot;
use O2CMS::Obj::Template::SlotList;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $object = bless {
    slotLists => {},
  }, $pkg;
  return $object;
}
#-------------------------------------------------------------------------------
sub newSlotList {
  my ($obj) = @_;
  return O2CMS::Obj::Template::SlotList->new( manager => $obj );
}
#-------------------------------------------------------------------------------
# return SlotList based on (front)page or template id
sub getSlotListById {
  my ($obj, $objectId) = @_;
  if (!$obj->{slotLists}->{$objectId}) {
    my $slotList = $obj->newSlotList();
    my @localSlots = $obj->getSlotsById($objectId);
    $slotList->setLocalSlots(@localSlots);
    $slotList->setExternalSlots( $obj->getExternalSlotsByLocalSlots(@localSlots) );
    $obj->{slotLists}->{$objectId} = $slotList;
  }
  return $obj->{slotLists}->{$objectId};
}
#-------------------------------------------------------------------------------
# like getSlotListById(), but will add information about <o2 slot> tags as well.
# Slots present in template, but not in SlotList will be added as external slots.
sub getSlotListWithTagsById {
  my ($obj, $objectId) = @_;
  # load regular slotlist
  my $slotList = $obj->getSlotListById($objectId);
  $obj->addTagsToSlotList($slotList, $objectId);
  return $slotList;
}
#-------------------------------------------------------------------------------
# parse template file and add info about <o2 slot> tags to an existing slot list
sub addTagsToSlotList {
  my ($obj, $slotList, $pageId) = @_;
  # extract information about <o2 slot> tags in page template
  require O2CMS::Publisher::PageRenderer;
  my $pageRenderer = O2CMS::Publisher::PageRenderer->new(
    media   => 'SlotTagExtractor', 
    page    => $context->getObjectById($pageId),
  );
  $pageRenderer->renderPage();
  my $slotTags = $pageRenderer->{media}->{slotTags};

  $slotList->setSlotTags( %{$slotTags} );
  return $slotList;
}
#-------------------------------------------------------------------------------
sub saveSlotList {
  my ($obj, $objectId, $slotList) = @_;
  $obj->saveSlots( $objectId, $slotList->getLocalSlots() );
}
#-------------------------------------------------------------------------------
sub getSlotsById { # Find slots on specified object
  my ($obj, $objectId) = @_;
  my @slots;
  
  # read all overrides first instead of one request per slot
  my %overrides = ();
  my $overrideSth = $db->sql('select slotId, name, value from O2CMS_OBJ_TEMPLATE_SLOTOVERRIDE where objectId=?', $objectId);
  while ( my ($slotId,$name,$value) = $overrideSth->nextArray() ) {
    $overrides{$slotId} = {} unless exists $overrides{$slotId};
    $overrides{$slotId}->{$name} = $value;
  }
  
  my $slotSth = $db->sql('select slotId, contentId, templateId from O2CMS_OBJ_TEMPLATE_SLOT where objectId = ?', $objectId);
  while ( my ($slotId, $contentId, $templateId) = $slotSth->nextArray() ) {
    my $slot = O2CMS::Obj::Template::Slot->new();
    $slot->setSlotId($slotId);
    $slot->setContentId($contentId);
    $slot->setTemplateId($templateId);
    $slot->setOverride( %{$overrides{$slotId}} ) if exists $overrides{$slotId};
    push @slots, $slot;
  }
  return @slots;
}
#-------------------------------------------------------------------------------
sub getExternalSlotsByLocalSlots {
  my ($obj, @localSlots) = @_;

  my @externalSlots;
  foreach my $localSlot (@localSlots) {
    next unless $localSlot->isTemplate();
    push @externalSlots, $obj->getExternalSlotsById( $localSlot->getContentId(), $localSlot->getSlotId(), 1 );
  }
  return @externalSlots;
}
#-------------------------------------------------------------------------------
##returns slots included in a grid, even those included via other grids
sub getExternalSlotsById {
  my ($obj, $objectId, $slotId, $slotIsExternal) = @_;
  my @slots = $obj->getSlotsById($objectId);
  my @result = $slotIsExternal ? @slots : (); # even local slots are external
  foreach my $slot (@slots) {
    my $fullSlotId = join '.', (split /\./, $slotId), (split /\./, $slot->getSlotId());
    $slot->setSlotId($fullSlotId);
    if ($slot->isTemplate()) {
      push @result, $obj->getExternalSlotsById($slot->getContentId(), $fullSlotId, 1);
    }
  }
  return @result;
}
#-------------------------------------------------------------------------------
sub saveSlots {
  my ($obj, $objectId, @slots) = @_;
  $db->sql( 'delete from O2CMS_OBJ_TEMPLATE_SLOT where objectId = ?',         $objectId );
  $db->sql( 'delete from O2CMS_OBJ_TEMPLATE_SLOTOVERRIDE where objectId = ?', $objectId );
  # XXX rewrite to prepared statements?
  foreach my $slot (@slots) {
    $db->insert(
      'O2CMS_OBJ_TEMPLATE_SLOT',
      objectId   => $objectId,
      slotId     => $slot->getSlotId(),
      contentId  => $slot->getContentId(),
      templateId => $slot->getTemplateId(),
    );
    my %override = $slot->getOverride();
    foreach my $name (keys %override) {
      $db->insert(
        'O2CMS_OBJ_TEMPLATE_SLOTOVERRIDE',
        objectId => $objectId,
        slotId   => $slot->getSlotId(),
        name     => $name,
        value    => $override{$name},
      );
    }
  }
}

#-------------------------------------------------------------------------------
sub deleteSlotsByObjectId {
  my ($obj, $objectId) = @_;
  $db->sql('delete from O2CMS_OBJ_TEMPLATE_SLOT where objectId=?',         $objectId);
  $db->sql('delete from O2CMS_OBJ_TEMPLATE_SLOTOVERRIDE where objectId=?', $objectId);
}
#-------------------------------------------------------------------------------
# Returns ids of templates used by an object
sub getObjectTemplateIdsByContentId {
  my ($obj, $objectId) = @_;
  my @ids = $db->selectColumn('select distinct(templateId) from O2CMS_OBJ_TEMPLATE_SLOT where contentId=?', $objectId);
  return @ids;
}
#-------------------------------------------------------------------------------
sub getObjectTemplatesByContentId {
  my ($obj, $objectId) = @_;
  my @ids = $obj->getObjectTemplateIdsByContentId($objectId);
  returns $context->getObjectsByIds(@ids);
}
#-------------------------------------------------------------------------------
1;
