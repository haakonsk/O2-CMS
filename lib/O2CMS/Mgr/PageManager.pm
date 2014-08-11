package O2CMS::Mgr::PageManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2CMS::Obj::Page;

#-------------------------------------------------------------------------------
sub init {
  my ($obj, $object) = @_;
  my $slotList = $obj->_getSlotManager()->getSlotListById( $object->getId() );
  $object->setSlotList($slotList);
  $obj->SUPER::init($object);
  return $object;
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;

  # Use inherited templateId from property, if not set
  if ( !defined $object->getTemplateId() ) {
    my $propertyName = 'pageTemplateId.' . $object->getMetaClassName();
    my $templateId   = $object->getPropertyValue($propertyName) || $object->getParent()->getPropertyValue($propertyName);

    die "Can't save page without templateId. '$propertyName' property had no value. ParentId is " . $object->getMetaParentId() unless $templateId;
    $object->setTemplateId($templateId);
  }

  $obj->SUPER::save($object);
  
  $obj->_getSlotManager()->saveSlotList( $object->getId(), $object->getSlotList() );

  my $pageCacher = $context->getSingleton('O2CMS::Publisher::PageCache');
  if ($pageCacher->isCached($object)) {
    $pageCacher->regenerateCached($object); # This will also remove "illegal" cache files
  }
  elsif (!$object->{restoringFromTrash} && !$object->isDeleted()) {
    $pageCacher->cacheObject($object);
  }
}
#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Page',
    title      => { type => 'varchar', multilingual => 1 },
    templateId => { type => 'O2CMS::Obj::Template'       },
  );
}
#-------------------------------------------------------------------------------
# Remove object from database
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
  $obj->_getSlotManager()->deleteSlotsByObjectId($objectId);
}
#-------------------------------------------------------------------------------
sub _getSlotManager {
  my ($obj) = @_;
  return $obj->{slotManager} ||= $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
}
#-------------------------------------------------------------------------------
# Publish an object based on "direct publish string" from gui (format: "$pageId:$slotId,$pageId2:,$slotId2"...)
# Does nothing if object is already visible on page.
sub publishDirectly {
  my ($obj, $objectId, $directPublishData) = @_;
  my $object = $context->getObjectById($objectId);
  die "Missing object with id $objectId" unless $object;

  foreach my $pageData (split /,/, $directPublishData) {
    my ($pageId, $slotId) = split /:/, $pageData;
    die "pageId ('$pageId') is not an integer" if $pageId !~ m{ \A \d+ \z }xms;
    my $page = $context->getObjectById($pageId);
    die "directPublishData ('$directPublishData') refers to a missing pageId ('$pageId')" unless $page;

    # Is it legal to publish object in page?
    next unless $object->isPublishable( $page->getUrl() );

    # Do not publish if object is already visible in page. 
    my $slotList = $page->getSlotListWithTags();
    foreach my $slot ( $slotList->getSlotsByContentId($objectId) ) { # slots containing object
      # Need to make sure slot is present in template as well (as <o2 slot> tag)
      # Sometimes a page has data for missing slots. This happens when <o2 slot> tags are removed or a template without the slot is used.
      return if $slotList->hasSlotTag( $slot->getSlotId() );
    }
    $slotList->placeObjectInSlot($slotId, $objectId);
    $obj->_getSlotManager()->saveSlotList($pageId, $slotList);
  }
}
#-------------------------------------------------------------------------------
sub setCategoryStandardPageIds {
  my ($obj, $categoryId, @pageIds) = @_;
  $db->sql('delete from O2CMS_OBJ_PAGE_STANDARDDIRECTPUBLISH where objectId = ?', $categoryId);
  my $position = 0;
  foreach my $pageId (@pageIds) {
    $db->insert(
      'O2CMS_OBJ_PAGE_STANDARDDIRECTPUBLISH',
      objectId => $categoryId,
      pageId   => $pageId,
      position => $position++,
    );
  }
}
#-------------------------------------------------------------------------------
sub getCategoryStandardPageIds {
  my ($obj, $categoryId) = @_;
  return $db->selectColumn('select pageId from O2CMS_OBJ_PAGE_STANDARDDIRECTPUBLISH where objectId = ? order by position', $categoryId);
}
#-------------------------------------------------------------------------------
sub getObjectByPlds {
  my ($obj, $plds) = @_;
  die "Not a valid PLDS" unless ref $plds eq 'HASH';
  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');
  my $object = $universalMgr->newObjectByClassName( $plds->{objectClass} );
  die "Class " . ref ($object) . " is not unserializable" unless $object->isSerializable();
  $object->setMetaPlds(    delete $plds->{_metaObject} );
  $object->setContentPlds( delete $plds->{data}        ) or die "Could not unserialize: $@";
  foreach (keys %{$plds}) {
    next if $_ eq 'objectClass';
    $object->{$_} = $plds->{$_};
  }
  return $object;
}
#-------------------------------------------------------------------------------1
1;
