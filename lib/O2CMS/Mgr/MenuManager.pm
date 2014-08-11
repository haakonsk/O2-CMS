package O2CMS::Mgr::MenuManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2CMS::Obj::Menu;
use O2CMS::Obj::Menu::MenuItem;

#-------------------------------------------------------------------------------
sub init {
  my ($obj, $object) = @_;
  $obj->SUPER::init($object);
  my $menu = $db->fetchHashRef( 'select * from O2CMS_OBJ_MENU where objectId=?', $object->getId() );
  $object->setTopLevelId( $menu->{topLevelId} );
  my @items = $db->fetchAll( 'select * from O2CMS_OBJ_MENU_ITEM where objectId=?', $object->getId() );
  my $currentLocale = $object->getCurrentLocale();
  foreach my $itemRow (@items) {
    next unless $object->isAvailableLocale( $itemRow->{localeCode} );
    $object->setCurrentLocale( $itemRow->{localeCode} );
    my $item = $object->getMenuItemByObjectId( $itemRow->{targetId} );
    $item->setObjectId(    $itemRow->{objectId}    );
    $item->setTargetId(    $itemRow->{targetId}    );
    $item->setParentId(    $itemRow->{parentId}    );
    $item->setPosition(    $itemRow->{position}    );
    $item->setExpandable(  $itemRow->{expandable}  );
    $item->setVisible(     $itemRow->{visible}     );
    $item->setDescription( $itemRow->{description} );

    $object->addMenuItem($item);
  }
  $object->setCurrentLocale($currentLocale);
  return $object;
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  my $isUpdate = $object->getId() > 0;
  $obj->SUPER::save($object);
  if ($isUpdate) {
    $db->idUpdate(
      'O2CMS_OBJ_MENU', 'objectId',
      objectId   => $object->getId(),
      topLevelId => $object->getTopLevelId(),
    );
  }
  else {
    $db->insert(
      'O2CMS_OBJ_MENU',
      objectId   => $object->getId(),
      topLevelId => $object->getTopLevelId(),
    );
  }
  
  $db->sql( 'delete from O2CMS_OBJ_MENU_ITEM where objectId=?', $object->getId() );
  my $currentLocale = $object->getCurrentLocale();
  foreach my $item ($object->getMenuItems()) {
    foreach my $locale ($item->getUsedLocales()) {
      next unless $object->isAvailableLocale($locale);
      
      $object->setCurrentLocale($locale);
      $db->insert(
        'O2CMS_OBJ_MENU_ITEM',
        objectId    => $object->getId(),
        targetId    => $item->getTargetId(),
        parentId    => $item->getParentId(),
        position    => $item->getPosition(),
        expandable  => $item->getExpandable(),
        visible     => $item->getVisible(),
        description => $item->getDescription(),
        localeCode  => $locale,
      );
    }
  }
  $object->setCurrentLocale($currentLocale);
}
#-------------------------------------------------------------------------------
# scan all categories below top level id for new objects to include
sub includeNewMenuItems {
  my ($obj, $menu, $object, $parentId) = @_;
  return unless $object;

  my $menuItem = $menu->getMenuItemByObjectId( $object->getId() );
  if ( !$menu->isMenuItemAdded($object->getId()) ) { # new metaItem discovered
    $menuItem->setObjectId(          $menu->getId()         );
    $menuItem->setTargetId(          $object->getId()       );
    $menuItem->setParentId(          $parentId              );
    $menuItem->setTarget(            $object                ); # cache object, since we have it available here
    $menuItem->setDefaultExpandable( $object->isContainer() );
    $menuItem->setDefaultVisible(    1                      );
    $menu->addMenuItem($menuItem);
  }
  if ( $menuItem->getExpandable() ) {
    my @children = $object->getChildren(
      undef, undef,
      -isa => 'O2CMS::Obj::WebCategory',
    );
    foreach my $child (@children) {
      $obj->includeNewMenuItems( $menu, $child, $object->getId() );
    }
  }
}
#-------------------------------------------------------------------------------
# An object has been changed, update menus
sub updateChangedObjectById {
  my ($obj, $objectId) = @_;

  my $object = $context->getObjectById($objectId);
  my @menus = $obj->getMenusByTargetId($objectId);
  debug "Menus involved in change: ". join ',', map { $_->getId() } @menus;
  foreach my $menu (@menus) {
    if ($object) { # object not removed
      my $menuItem = $menu->getMenuItemByObjectId($objectId);
      if ( $menu->isMenuItemAdded($objectId) ) {
        debug "Updating menu item $objectId";
        # object moved?
        if ( $menuItem->getParentId() != $object->getMetaParentId() ) {
          debug "Menu item parentId and object parentId differ";
          my $parent = $context->getObjectById( $menuItem->getParentId() );
          if ($parent) {
            my $isChild = grep { $_->getId() == $objectId }  $object->getChildren();
            debug "Object is listed below menu item parentId: $isChild";
            if (!$isChild) {
              debug "Child not listed below menu item parentId. Move menu item to " . $object->getMetaParentId();
              $menuItem->setParentId( $object->getMetaParentId() );
            }
          }
        }
        else {
          debug "ParentId " . $menuItem->getParentId() . "==" . $object->getMetaParentId() . ", do not move.";
        }
      }
      else {
        debug "Adding new menu item $objectId";
        $menuItem->setObjectId( $menu->getId()             );
        $menuItem->setTargetId( $object->getId()           );
        $menuItem->setParentId( $object->getMetaParentId() );
        $menuItem->setTarget(   $object                    );
        $menuItem->setDefaultExpandable($object->isContainer());
        $menuItem->setDefaultVisible(1);
        $menu->addMenuItem($menuItem);
      }
    }
    else { # object removed
      debug "Removing object $objectId from menu";
      $menu->removeMenuItemById($objectId);
    }
    my $menuItem = $menu->getMenuItemByObjectId($objectId);
    debug "Save menu with " . $menuItem->getParentId() . " as parentId for $objectId";

    $menu->save();
  }
}
#-------------------------------------------------------------------------------
# return menus where target are already an item + menus where parent of target is registered (item should appear below parent in menu)
sub getMenusByTargetId {
  my ($obj, $targetId) = @_;

  my @menuIds;
  my $target = $context->getObjectById($targetId);
  if ($target) {
    debug "Look for menus with targetId $targetId or ".$target->getMetaParentId();
    @menuIds = $db->selectColumn('select distinct(objectId) from O2CMS_OBJ_MENU_ITEM where targetId=? or targetId=?', $targetId, $target->getMetaParentId());
  }
  else {
    debug "Look for menus with targetId $targetId";
    @menuIds = $db->selectColumn('select distinct(objectId) from O2CMS_OBJ_MENU_ITEM where targetId=?', $targetId);
  }
  return $context->getObjectsByIds(@menuIds);
}
#-------------------------------------------------------------------------------
# remove object from database
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
  $db->sql('delete from O2CMS_OBJ_MENU      where objectId = ?', $objectId);
  $db->sql('delete from O2CMS_OBJ_MENU_ITEM where objectId = ?', $objectId);
}
#-------------------------------------------------------------------------------
1;
