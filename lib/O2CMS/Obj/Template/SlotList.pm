package O2CMS::Obj::Template::SlotList;

# Holds all slots in a grid. Both slots inherited from other grids and local.

use strict;

use O2 qw($context);
use O2CMS::Obj::Template::Slot;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {
    localSlots    => {}, # slots setLocalSlot on current grid
    externalSlots => {}, # slots inherited from other grids
    manager       => $init{manager},
  }, $pkg;
}
#-------------------------------------------------------------------------------
sub getManager {
  my ($obj) = @_;
  return $obj->{manager};
}
#-------------------------------------------------------------------------------
sub setLocalSlot {
  my ($obj, $slot) = @_;
  $obj->_setSlot('localSlots', $slot);
}
#-------------------------------------------------------------------------------
sub setExternalSlot {
  my ($obj, $slot) = @_;
  $obj->_setSlot('externalSlots', $slot);
}
#-------------------------------------------------------------------------------
sub _setSlot {
  my ($obj, $type, $slot) = @_;
  my $slotId = $slot->getSlotId();
  die "Missing slotId in Slot" unless $slotId;
  $obj->{$type}->{$slotId} = $slot;
}
#-------------------------------------------------------------------------------
sub setLocalSlots {
  my ($obj, @slots) = @_;
  $obj->_setSlots('localSlots', @slots);
}
#-------------------------------------------------------------------------------
sub setExternalSlots {
  my ($obj, @slots) = @_;
  $obj->_setSlots('externalSlots', @slots);
}
#-------------------------------------------------------------------------------
sub addExternalSlots {
  my ($obj, @externalSlots) = @_;
  foreach my $slot (@externalSlots) {
#    next if $obj->{externalSlots}->{ $slot->getSlotId() };
    $obj->setExternalSlot($slot);
  }
}
#-------------------------------------------------------------------------------
sub _setSlots {
  my ($obj, $type, @slots) = @_;
  $obj->{$type} = {};
  foreach my $slot (@slots) {
    $obj->_setSlot($type, $slot);
  }
}
#-------------------------------------------------------------------------------
# list both local and external slots
sub getSlots {
  my ($obj) = @_;
  my %slots = ( %{ $obj->{externalSlots} }, %{ $obj->{localSlots} } );
  return values %slots;
}
#-------------------------------------------------------------------------------
sub getLocalSlots {
  my ($obj) = @_;
  return values %{ $obj->{localSlots} };
}
#-------------------------------------------------------------------------------
sub getExternalSlots {
  my ($obj) = @_;
  return values %{ $obj->{externalSlots} };
}
#-------------------------------------------------------------------------------
sub getLocalSlotById {
  my ($obj, $slotId) = @_;
  return $obj->{localSlots}->{$slotId};
}
#-------------------------------------------------------------------------------
sub getExternalSlotById {
  my ($obj, $slotId) = @_;
  return $obj->{externalSlots}->{$slotId};
}
#-------------------------------------------------------------------------------
# returns local slot or default to external
sub getSlotById {
  my ($obj, $slotId) = @_;
  my $slot = $obj->{localSlots}->{$slotId};
  return $slot if $slot && $slot->getContentId() && $slot->getContentId() > 0;
  return $obj->{externalSlots}->{$slotId} || $slot;
}
#-------------------------------------------------------------------------------
# convenience method for setting slots from a hash. Format: ('content.slot1'=> {templateId=>72, contentId=>64, override=>{title=>'my title'}})
sub setLocalSlotsHash {
  my ($obj, %slots) = @_;
  $obj->setLocalSlots( $obj->_slotHashToObjects(%slots) );
}
#-------------------------------------------------------------------------------
# convenience method for setting external slots from a hash. Format: ('content.slot1'=> {templateId=>72, contentId=>64, override=>{title=>'my title'}})
sub setExternalSlotsHash {
  my ($obj, %slots) = @_;
  $obj->setExternalSlots( $obj->_slotHashToObjects(%slots) );
}
#-------------------------------------------------------------------------------
# convert hash to slot objects
sub _slotHashToObjects {
  my ($obj, %slots) = @_;
  my @slots;
  foreach my $slotId (keys %slots) {
    my $slot = O2CMS::Obj::Template::Slot->new();
    $slot->setSlotId($slotId);
    $slot->setContentId(   $slots{$slotId}->{contentId}  );
    $slot->setTemplateId(  $slots{$slotId}->{templateId} );
    $slot->setOverride( %{ $slots{$slotId}->{override} } ) if $slots{$slotId}->{override};
    push @slots, $slot;
  }
  return @slots;
}
#-------------------------------------------------------------------------------
sub serialize {
  my ($obj) = @_;
  my %plds;
  foreach my $slot ($obj->getLocalSlots()) {
    $plds{ $slot->getSlotId() } = {
      contentId  => $slot->getContentId(),
      templateId => $slot->getTemplateId(),
      override   => { $slot->getOverride() },
    };
  }
  return \%plds;
}
#-------------------------------------------------------------------------------
sub unserialize {
  my ($obj, $plds) = @_;
  my @slots = $obj->_slotHashToObjects( %{$plds} );
  $obj->setLocalSlots(@slots);
}
#-------------------------------------------------------------------------------
# set hash of all attributes found in <o2 slot> tags (slotId=>attributeHash)
sub setSlotTags{
  my ($obj, %slotTags) = @_;
  $obj->{slotTags} = { %slotTags };
}
#-------------------------------------------------------------------------------
# return an attribute from <o2 slot> tag associated with slot
# (might not be available - tag attributes are only included when using $slotMgr->getSlotListWithTagsById())
sub getSlotTagAttributeById {
  my ($obj, $slotId, $attributeName) = @_;
  die 'Cannot getSlotTagAttributeById() before slot tags are loaded' unless $obj->areSlotTagsLoaded();
  return $obj->{slotTags}->{$slotId}->{$attributeName};
}
#-------------------------------------------------------------------------------
sub areSlotTagsLoaded {
  my ($obj) = @_;
  return exists $obj->{slotTags};
}
#-------------------------------------------------------------------------------
# returns true if template has <o2 slot> tag with id $slotId
sub hasSlotTag {
  my ($obj, $slotId) = @_;
  die 'Cannot getSlotTagAttributeById() before slot tags are loaded' unless $obj->areSlotTagsLoaded();
  return exists $obj->{slotTags}->{$slotId};
}
#-------------------------------------------------------------------------------
# return all <o2 slot> tags as a list of hashes. Each hash contains all attributes found in one <o2 slot> tag.
sub getSlotTags {
  my ($obj) = @_;
  die 'Cannot getSlotTags() before slot tags are loaded' unless $obj->areSlotTagsLoaded();
  return values %{ $obj->{slotTags} };
}
#-------------------------------------------------------------------------------
sub placeObjectInSlot {
  my ($obj, $slotId, $contentId) = @_;
  die 'Cannot getSlotTags() before slot tags are loaded' unless $obj->areSlotTagsLoaded();
  
  my $tag = $obj->{slotTags}->{$slotId};
  die "No tag with slotId '$slotId'" unless $tag;

  my $slot = $obj->getSlotById($slotId); # use getLocalSlotById() instead to avoid external slots from beeing part of slot chain
  if( $tag->{next} && $slot && $slot->getContentId()>0) {
    # move down slot chain
    my $nextId = $obj->_resolveNextSlot( $tag->{next}, $slotId );
    die "next attribute in slot tag points to non existent slot ('$tag->{next}')" unless $nextId;
    $obj->placeObjectInSlot( $nextId, $slot->getContentId(), $slot->getTemplateId() ); # XXX handle templates
  }
  
  if (!$slot) {
    $slot = O2CMS::Obj::Template::Slot->new();
    $slot->setSlotId($slotId);
  }
  $slot->setContentId($contentId);

  $obj->_makeSureSlotHasProperTemplate($slot);
  $obj->setLocalSlot($slot);
}
#-------------------------------------------------------------------------------
sub clearSlot {
  my ($obj, $slotId) = @_;
  my $slot = $obj->{ localSlots }->{$slotId};
  my $tag  = $obj->{ slotTags   }->{$slotId};

  if ($tag->{next} && $slot && $slot->getContentId() > 0) {
    # If slot is part of a slot chain, fill the hole that would have appeared if we just deleted
    my $nextId;
    while ($tag->{next} && $slot && $slot->getContentId() > 0) {
      $nextId = $obj->_resolveNextSlot( $tag->{next}, $slotId );
      last unless $nextId;
      my $nextSlot = $obj->{localSlots}->{$nextId};
      last unless $nextSlot;
      $slot->setContentId( $nextSlot->getContentId() );
      $obj->_makeSureSlotHasProperTemplate($slot);
      $slot = $nextSlot;
      $tag  = $obj->{slotTags}->{$nextId};
    }
    delete $obj->{ localSlots }->{ $slot->{slotId} };
    delete $obj->{ slotTag    }->{ $slot->{slotId} };
  }
  else {
    delete $obj->{ localSlots }->{$slotId};
    delete $obj->{ slotTags   }->{$slotId};
  }
}
#-------------------------------------------------------------------------------
sub _makeSureSlotHasProperTemplate {
  my ($obj, $slot) = @_;

  return unless $slot->getContentId()>0; # do not care about template if we have no contente

  my $content  = $context->getObjectById( $slot->getContentId() );
  return unless $content; # Can't read content
  my $template = $slot->getTemplateId()>0 ? $context->getObjectById($slot->getTemplateId()) : undef;
  # slot has template, and it fits the content?
  return if $template && $template->isUsableForClass( $content->getMetaClassName() );

  # look for template matching templateMatch attribute from <o2 slot>. Or whose filename is 'default.html'
  my $objectTemplateMgr = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager');
  my $templateMatch   = $obj->getSlotTagAttributeById( $slot->getSlotId(), 'templateMatch'   ); # from templateMatch="" attribute in <o2 slot> tag...
  my $defaultTemplate = $obj->getSlotTagAttributeById( $slot->getSlotId(), 'defaultTemplate' ); # from defaultTemplate="" attribute in <o2 slot> tag...
  my @templates = $objectTemplateMgr->queryTemplates(
    class         => $content->getMetaClassName(),
    templateMatch => $templateMatch,
  );
  die 'No templates for '.$content->getMetaClassName()." (using templateMatch '$templateMatch')" unless @templates;

  foreach my $template (@templates) {
    if ( $template->getPrettyName() eq $defaultTemplate || $template->getFileName() eq $defaultTemplate ) {
      $slot->setTemplateId( $template->getId() );
      return;
    }
  }
  foreach my $template (@templates) {
    if ( $template->getFileName() eq 'default.html' ) {
      $slot->setTemplateId( $template->getId() );
      return;
    }
  }

  # sort templates alphabetically, and use first
  @templates = sort { $a->getPrettyName() cmp $b->getPrettyName() } @templates;
  $slot->setTemplateId( $templates[0]->getId() );
}
#-------------------------------------------------------------------------------
# next="" attributes usually point to slots in the same template (relative), or it might be absolute
sub _resolveNextSlot {
  my ($obj, $slotId, $relativeToSlotId) = @_;
  my ($prefix) = $relativeToSlotId =~ /(.*?)\.\w+$/; # all but the last part
  return "$prefix.$slotId" if $obj->{slotTags}->{"$prefix.$slotId"}; # try with same prefix as the tag we come from
  return $slotId           if $obj->{slotTags}->{$slotId          }; # slotId contains full path?
  return; # not found
}
#-------------------------------------------------------------------------------
sub getDirectPublishTags {
  my ($obj) = @_;
  die "Can't getSlotTags() before slot tags are loaded" unless $obj->areSlotTagsLoaded();
  
  my @tags = $obj->getSlotTags();
  @tags = grep { $_->{directPublishPriority} > 0                             } @tags; # filter out slots without directPublishPriority
  @tags = sort { $a->{directPublishPriority} <=> $b->{directPublishPriority} } @tags; # sort by priority
  return @tags;
}
#-------------------------------------------------------------------------------
# returns slot containing $contentId (only first, if more exists)
sub getSlotsByContentId {
  my ($obj, $contentId) = @_;
  my @slots;
  foreach my $slot ( $obj->getSlots() ) {
    push @slots, $slot if $slot->getContentId() == $contentId;
  }
  return @slots;
}
#-------------------------------------------------------------------------------
# returns content in a more or less human readable form:)
sub asString {
  my ($obj,$asHtml) = @_;
  my $str = '';
  $obj->_updateExternalSlots() if $obj->{mustUpdateExternalSlots};
  foreach my $slotType (qw|localSlots externalSlots|) {
    $str .= "$slotType:\n";
    foreach my $slotId ( sort keys %{ $obj->{$slotType} } ) {
      my $slot = $obj->{$slotType}->{$slotId};
      $str .= "\t" . $slot->asString($asHtml) . "\n";
    }
  }
  return $str;
}
#-------------------------------------------------------------------------------
1;
