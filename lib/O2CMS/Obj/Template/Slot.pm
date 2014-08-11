package O2CMS::Obj::Template::Slot;

# Description: Holds information about one slot. Slots are not full O2 objects.
# A slot is an object position in a webpage and consists of:
#  - object to display (objectId)
#  - what template to use when displaying it (templateId)
#  - possible override values (i.e. a new object title)

use strict;

#------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {
    slotId          => undef,
    templateId      => undef,
    contentId       => undef,
    override        => {},
  }, $pkg;
}
#------------------------------------------------------------------
sub setSlotId {
  my ($obj, $slotId) = @_;
  $obj->{slotId} = $slotId;
}
#------------------------------------------------------------------
sub getSlotId {
  my ($obj) = @_;
  return $obj->{slotId};
}
#------------------------------------------------------------------
sub setTemplateId {
  my ($obj, $templateId) = @_;
  $obj->{templateId} = $templateId;
}
#------------------------------------------------------------------
sub getTemplateId {
  my ($obj) = @_;
  return $obj->{templateId};
}
#------------------------------------------------------------------
sub setContentId {
  my ($obj, $contentId) = @_;
  $obj->{contentId} = $contentId;
}
#------------------------------------------------------------------
sub getContentId {
  my ($obj) = @_;
  return $obj->{contentId};
}
#------------------------------------------------------------------
sub setOverride {
  my ($obj, %override) = @_;
  $obj->{override} = \%override;
}
#------------------------------------------------------------------
sub getOverride {
  my ($obj) = @_;
  return wantarray  ?  %{ $obj->{override} }  :  $obj->{override};
}
#------------------------------------------------------------------
sub setOverrideByName {
  my ($obj, $name, $value) = @_;
  return $obj->{override}->{$name} = $value;
}
#------------------------------------------------------------------
sub getOverrideByName {
  my ($obj, $name) = @_;
  return $obj->{override}->{$name};
}
#------------------------------------------------------------------
# Returns true if this slot contains a grid (or include)
sub isTemplate {
  my ($obj) = @_;
  return $obj->getContentId()  &&  $obj->getContentId() > 0  &&  !$obj->getTemplateId();
}
#------------------------------------------------------------------
# convenience method returning whole object as a hash
sub serialize {
  my ($obj) = @_;
  return {
    slotId     => $obj->getSlotId(),
    contentId  => $obj->getContentId(), 
    templateId => $obj->getTemplateId(), 
    override   => $obj->getOverride(),
  };
}
#------------------------------------------------------------------
sub unserialize {
  my ($obj, $serialized) = @_;
  $obj->setSlotId(      $serialized->{slotId}     );
  $obj->setContentId(   $serialized->{contentId}  );
  $obj->setTemplateId(  $serialized->{templateId} );
  $obj->setOverride( %{ $serialized->{override} } );
}
#------------------------------------------------------------------
sub toHash {
  my ($obj) = @_;
  return (
    contentId  => $obj->getContentId(),
    templateId => $obj->getTemplateId(),
    override   => { $obj->getOverride() },
  );
}
#------------------------------------------------------------------
sub asString {
  my ($obj, $asHtml) = @_;
  my $str = '';
  if ($asHtml) {
    $str .= "$obj->{slotId}: c<a href=./dumpObject?objectId=$obj->{contentId}>$obj->{contentId}</a>/t<a href=./dumpObject?objectId=$obj->{templateId}>$obj->{templateId}</a> [";
  }
  else {
    $str .= "$obj->{slotId}: c$obj->{contentId}/t$obj->{templateId} [";
  }
  foreach my $name (sort keys %{$obj->{override}} ) {
    $str .= "$name: '$obj->{override}->{$name}' ";
  }
  $str .= "]";
  return $str;
}
#------------------------------------------------------------------
1;
