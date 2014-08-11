package O2CMS::Obj::Menu::MenuItem;

# XXX Rewrite to use Model

use strict;

use O2 qw($context);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  die "No menu object passed to MenuItem" unless $init{menu};
  my $obj = bless({menu=>$init{menu}}, $pkg);
  $obj->{data} = {};
  $obj->{data}->{objectId}    = undef;  # menuId
  $obj->{data}->{targetId}    = undef;  # id of included object
  $obj->{data}->{parentId}    = undef;  # parent of included object (where it should appear in menu)
  $obj->{data}->{target}      = undef;  # included object (cache)
  $obj->{data}->{position}    = {};  # sort order for item (among its siblings) [multilingual]
  $obj->{data}->{expandable}  = {};  # should it be possible to expand item     [multilingual]
  $obj->{data}->{visible}     = {};  # is item visible                          [multilingual]
  $obj->{data}->{description} = {};  # descriptive text                         [multilingual]
  $obj->{data}->{defaultPosition}    = undef;  # default position (if multilingual not set)
  $obj->{data}->{defaultExpandable}  = undef;  # default expandable (if multilingual not set)
  $obj->{data}->{defaultVisible}     = undef;  # default visible (if multilingual not set)
  return $obj;
}
#-------------------------------------------------------------------------------
sub getObjectPlds {
  my ($obj) = @_;
  my $plds = {
    meta        => {},
    data        => $obj->getContentPlds(),
    keywordIds  => [],
    objectClass => ref $obj,
  };
  return $plds;
}
#-------------------------------------------------------------------------------
sub getContentPlds {
  my ($obj) = @_;
  my %data = %{ $obj->{data} };
  undef $data{target}; # We have a targetId field as well, so don't need to store target, I guess..
  return \%data;
}
#-------------------------------------------------------------------------------
# menuId
sub setObjectId {
  my ($obj, $objectId) = @_;
  $obj->{data}->{objectId} = $objectId;
}
#-------------------------------------------------------------------------------
sub getObjectId {
  my ($obj) = @_;
  return $obj->{data}->{objectId};
}
#-------------------------------------------------------------------------------
# objectId of included object
sub setTargetId {
  my ($obj, $targetId) = @_;
  $obj->{data}->{targetId} = $targetId;
}
#-------------------------------------------------------------------------------
sub getTargetId {
  my ($obj) = @_;
  return $obj->{data}->{targetId};
}
#-------------------------------------------------------------------------------
# parent of included object (where it should appear in menu)
sub setParentId {
  my ($obj, $parentId) = @_;
  $obj->{data}->{parentId} = $parentId;
}
#-------------------------------------------------------------------------------
sub getParentId {
  my ($obj) = @_;
  return $obj->{data}->{parentId};
}
#-------------------------------------------------------------------------------
sub getTargetName {
  my ($obj) = @_;
  my $target = $obj->getTarget();
  return unless $target;
  my $currentLocale = $target->getCurrentLocale();
  
  $target->setCurrentLocale($obj->{menu}->getCurrentLocale());
  my $name = $target->can('getTitle') ? $target->getTitle() : $target->getMetaName();
  $name = $target->getMetaName() unless $name;
  
  $target->setCurrentLocale($currentLocale);
  return $name;
}
#-------------------------------------------------------------------------------
sub getTargetClassName {
  my ($obj) = @_;
  my $target = $obj->getTarget();
  return $target ? $target->getMetaClassName() : undef;
}
#-------------------------------------------------------------------------------
sub setDescription {
  my ($obj, $description) = @_;
  $obj->{data}->{description}->{$obj->{menu}->getCurrentLocale()} = $description;
}
#-------------------------------------------------------------------------------
# extra description of target object
sub getDescription {
  my ($obj) = @_;
  return $obj->{data}->{description}->{$obj->{menu}->getCurrentLocale()} || '';
}
#-------------------------------------------------------------------------------
# included object (cached)
sub setTarget {
  my ($obj, $target) = @_;
  $obj->{data}->{target} = $target;
}
#-------------------------------------------------------------------------------
sub getTarget {
  my ($obj) = @_;
  return $obj->{data}->{target} if defined $obj->{data}->{target};
  return $obj->{data}->{target} = $context->getObjectById( $obj->getTargetId() );
}
#-------------------------------------------------------------------------------
# sort order for item (among its siblings)
sub setPosition {
  my ($obj, $position) = @_;
  $obj->{data}->{position}->{$obj->{menu}->getCurrentLocale()} = $position;
}
#-------------------------------------------------------------------------------
sub getPosition {
  my ($obj) = @_;
  my $position = $obj->{data}->{position}->{$obj->{menu}->getCurrentLocale()};
  return defined $position ? $position : $obj->{data}->{defaultPosition};
}
#-------------------------------------------------------------------------------
# should it be possible to expand item if true
sub setExpandable {
  my ($obj, $expandable) = @_;
  $obj->{data}->{expandable}->{$obj->{menu}->getCurrentLocale()} = $expandable;
}
#-------------------------------------------------------------------------------
sub getExpandable {
  my ($obj) = @_;
  my $expandable = $obj->{data}->{expandable}->{$obj->{menu}->getCurrentLocale()};
  return $expandable ? 1 : 0 if defined $expandable;
  return $obj->{data}->{defaultExpandable} ? 1 : 0;
}
#-------------------------------------------------------------------------------
# is item visible
sub setVisible {
  my ($obj, $visible) = @_;
  $obj->{data}->{visible}->{$obj->{menu}->getCurrentLocale()} = $visible;
}
#-------------------------------------------------------------------------------
sub getVisible {
  my ($obj) = @_;
  my $visible = $obj->{data}->{visible}->{$obj->{menu}->getCurrentLocale()};
  return $visible ? 1 : 0 if defined $visible;
  return $obj->{data}->{defaultVisible} ? 1 : 0;
}
#-------------------------------------------------------------------------------
# fallback for position (if multilingual version not set)
sub setDefaultPosition {
  my ($obj, $defaultPosition) = @_;
  $obj->{data}->{defaultPosition} = $defaultPosition;
}
#-------------------------------------------------------------------------------
# fallback for expandable (if multilingual version not set)
sub setDefaultExpandable {
  my ($obj, $defaultExpandable) = @_;
  $obj->{data}->{defaultExpandable} = $defaultExpandable;
}
#-------------------------------------------------------------------------------
# fallback for visible (if multilingual version not set)
sub setDefaultVisible {
  my ($obj, $defaultVisible) = @_;
  $obj->{data}->{defaultVisible} = $defaultVisible;
}
#-------------------------------------------------------------------------------
sub getUrl {
  my ($obj) = @_;
  return $obj->{menu}->getMenuItemUrl( $obj->getTargetId() );
}
#-------------------------------------------------------------------------------
# returns true if this item has been marked as expanded (item, or one of it's children is the current catgory)
sub setExpanded {
  my ($obj, $expanded) = @_;
  $obj->{expanded} = $expanded;
}
#-------------------------------------------------------------------------------
sub getExpanded {
  my ($obj) = @_;
  return $obj->{expanded} ? 1 : 0;
}
#-------------------------------------------------------------------------------
# returns true if this item is located on the top level of the menu tree (has no parent items)
sub isTopLevel {
  my ($obj) = @_;
  return 0 unless $obj->getTarget();
  return $obj->{menu}->getTopLevelId() == $obj->getTarget()->getMetaParentId() ? 1 : 0;
}
#-------------------------------------------------------------------------------
sub getUsedLocales {
  my ($obj) = @_;
  return keys %{ $obj->{data}->{position} };
}
#-------------------------------------------------------------------------------
sub asString {
  my ($obj) = @_;
  return "objectId: $obj->{data}->{objectId}, targetId: $obj->{data}->{targetId}, parentId: $obj->{data}->{parentId}, position: ".$obj->getPosition().", expandable: ".$obj->getExpandable().", visbible: ".$obj->getVisible().", expanded: ".$obj->getExpanded().", name: ".$obj->getTargetName();
}
#-------------------------------------------------------------------------------
1;
