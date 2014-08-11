package O2CMS::Obj::Page;

use strict;

use base 'O2::Obj::Object';
use base 'O2CMS::Role::Obj::Page';

use O2 qw($context);
use O2CMS::Obj::Template::SlotList;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  $obj->{slotList} = $context->getSingleton('O2CMS::Mgr::Template::SlotManager')->newSlotList();
  return $obj;
}
#-------------------------------------------------------------------------------
sub isPageCachable {
  return 1;
}
#-------------------------------------------------------------------------------
sub setTemplateId {
  my ($obj, $templateId) = @_;
  $obj->setModelValue('templateId', $templateId);
  # use slots from template as default slots
  my $slotMgr = $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
  my @slots         = $slotMgr->getSlotsById($templateId);
  my @externalSlots = $slotMgr->getExternalSlotsByLocalSlots(@slots);
  my $slotList = $obj->getSlotList();
  $slotList->addExternalSlots(@slots, @externalSlots);
}
#-------------------------------------------------------------------------------
# returns template object
sub getTemplate {
  my ($obj) = @_;
  return unless $obj->getTemplateId();
  return $context->getObjectById( $obj->getTemplateId() );
}
#-------------------------------------------------------------------------------
# returns template text
sub getTemplateRef {
  my ($obj) = @_;
  my $template = $obj->getTemplate();
  return $template ? $template->getTemplateRef() : undef;
}
#-------------------------------------------------------------------------------
sub setSlotList {
  my ($obj, $slotList) = @_;
  $obj->{slotList} = $slotList;
}
#-------------------------------------------------------------------------------
sub getSlotList {
  my ($obj) = @_;
  return $obj->{slotList};
}
#-------------------------------------------------------------------------------
sub getSlotById {
  my ($obj, $slotId) = @_;
  return $obj->getSlotList()->getSlotById($slotId);
}
#-------------------------------------------------------------------------------
sub setSlot {
  my ($obj, $slot) = @_;
  $obj->getSlotList()->setLocalSlot($slot);
}
#-------------------------------------------------------------------------------
sub getSlotContentById {
  my ($obj, $slotId) = @_;
  my $slot = $obj->getSlotById($slotId);
  return if !$slot || !$slot->getContentId();
  
  my $object = $context->getObjectById( $slot->getContentId() );
  return unless $object;
  
  $object = $object->getUnserializedObject() if $object->isa('O2CMS::Obj::Draft');
  return $object;
}
#-------------------------------------------------------------------------------
# set whole category path from a O2CMS::Publisher::ResolvedUrl object
sub setResolvedUrl {
  my ($obj, $resolvedUrl) = @_;
  $obj->{resolvedUrl} = $resolvedUrl;
  my @categories = (undef); # first category is installation
  push @categories, $context->getObjectById(   $resolvedUrl->getSiteId()          );
  push @categories, $context->getObjectsByIds( $resolvedUrl->getCategoryPathIds() );

  my $contentObject = $context->getObjectById( $resolvedUrl->getContentObjectId() );
  push @categories, $contentObject if $contentObject->isa('O2CMS::Obj::WebCategory');

  $obj->{categories} = \@categories;
  $obj->{categoriesLoaded} = 1;
}
#-------------------------------------------------------------------------------
sub getResolvedUrl {
  my ($obj) = @_;
  return $obj->{resolvedUrl};
}
#-------------------------------------------------------------------------------
sub getUrl {
  my ($obj) = @_;
  my $webCategory = $obj->getWebCategory();
  return $webCategory->getUrl() if $webCategory;
  return undef;
}
#-------------------------------------------------------------------------------
sub getSite {
  my ($obj) = @_;
  $obj->_loadCategories();
  return $obj->{categories}->[1];
}
#-------------------------------------------------------------------------------
# returns webcategory where page resides
sub getWebCategory {
  my ($obj) = @_;
  $obj->_loadCategories();
  my $category = $obj->{categories}->[-1];
  return if !$category && !$obj->getId(); # Exception for page objects generated in the displayPage method
  die sprintf "Didn't find web category for page '%s' (%d)", $obj->getMetaName(), $obj->getId() unless $category;
  return $category if $category->isa('O2CMS::Obj::WebCategory');
  die sprintf "Page ('%s' with ID %d) resides in a category ('%s' with ID %d) that's not a web category", $obj->getMetaName(), $obj->getId(), $category->getMetaName(), $category->getId() if $category->isa('O2CMS::Obj::Category');
  die sprintf "Page ('%s' with ID %d) resides in a something ('%s' with ID %d) that's not a category",    $obj->getMetaName(), $obj->getId(), $category->getMetaName(), $category->getId();
}
#-------------------------------------------------------------------------------
sub getCategoryPath {
  my ($obj) = @_;
  $obj->_loadCategories();
  my @categories = @{ $obj->{categories} };
  my @path = @categories[1..$#categories];
  return wantarray ? @path : \@path;
}
#-------------------------------------------------------------------------------
sub _loadCategories {
  my ($obj) = @_;
  return if $obj->{categoriesLoaded};
  
  my @categories = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPath( $obj->getMetaParentId() );
  $obj->{categories} = \@categories;
  $obj->{categoriesLoaded} = 1;
}
#-------------------------------------------------------------------------------
sub isDescendentOf {
  my ($obj, $categoryOrCategoryId) = @_;
  return 0 unless $categoryOrCategoryId;
  
  my $categoryId = ref $categoryOrCategoryId  ?  $categoryOrCategoryId->getId()  :  $categoryOrCategoryId;
  $obj->_loadCategories();
  foreach (@{ $obj->{categories} }) {
    next unless $_;
    return 1 if $categoryId == $_->getId();
  }
  return 0;
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1;
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isMultilingual {
  return 1;
}
#-------------------------------------------------------------------------------
sub asString {
  my ($obj, $asHtml) = @_;
  my $str = '';
  $str .= $obj->getMetaClassName() . '/' . $obj->getId() . "\n";
  $str .= $obj->getSlotList()->asString($asHtml);
  return $str;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isCachable {
  return 0;
}
#-------------------------------------------------------------------------------
sub getContentPlds {
  my ($obj) = @_;
  my %plds = %{ $obj->{data} };
  $plds{slotList} = $obj->getSlotList()->serialize();
  return \%plds;
}
#-------------------------------------------------------------------------------
sub setContentPlds {
  my ($obj, $plds) = @_;
  my $slots = delete $plds->{slotList};
  $obj->getSlotList()->unserialize($slots);
  $obj->setCurrentLocale( delete $plds->{currentLocale} ) if $plds->{currentLocale};
  $obj->{data} = $plds;
  return 1;
}
#-------------------------------------------------------------------------------
1;
