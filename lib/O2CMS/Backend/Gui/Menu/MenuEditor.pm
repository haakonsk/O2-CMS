package O2CMS::Backend::Gui::Menu::MenuEditor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $config);
use O2CMS::Obj::Menu::MenuItem;

#------------------------------------------------------------------
sub create {
  my ($obj) = @_;
  my $menu = $context->getSingleton('O2CMS::Mgr::MenuManager')->newObject();
  $menu->setTopLevelId( $obj->getParam('parentId') );
  $menu->includeNewMenuItems();
  $obj->_edit($menu);
}
#------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  my $menu = $context->getObjectById( $obj->getParam('objectId') );
  $obj->error("Menu object not found") unless $menu;
  $menu->includeNewMenuItems();
  $obj->_edit($menu);
}
#------------------------------------------------------------------
sub _edit {
  my ($obj, $menu) = @_;
  my @locales = $config->getArray('o2.locales');
  $obj->display(
    'edit.html',
    menu    => $menu,
    locales => \@locales,
  );
}
#------------------------------------------------------------------
sub save {
  my ($obj) = @_;

  my $menuMgr = $context->getSingleton('O2CMS::Mgr::MenuManager');
  my $menu = $obj->getParam('objectId')  ?  $context->getObjectById( $obj->getParam('objectId') )  :  $menuMgr->newObject();
  $obj->error("Menu not found") unless $menu;
  $menu->setMetaParentId( $obj->getParam('parentId')   );
  $menu->setMetaName(     $obj->getParam('name')       );
  $menu->setTopLevelId(   $obj->getParam('topLevelId') );
  
  use O2::Javascript::Data;
  my $data = O2::Javascript::Data->new();
  my $menuItems = $data->undumpXml( $obj->getParam('menuItems') );

  my %idsToRemove;
  $menu->clearMenuItems();
  foreach my $locale (keys %$menuItems) {
    $menu->setCurrentLocale($locale);
    foreach my $item (values %{$menuItems->{$locale}}) {
      $idsToRemove{ $item->{id} } = 1 if $item->{deleted};
      my $menuItem = $menu->getMenuItemByObjectId( $item->{id} );
      $menuItem->setObjectId(    $menu->getId()       );
      $menuItem->setTargetId(    $item->{id}          );
      $menuItem->setParentId(    $item->{parentId}    );
      $menuItem->setPosition(    $item->{position}    );
      $menuItem->setExpandable(  $item->{expandable}  );
      $menuItem->setVisible(     $item->{visible}     );
      $menuItem->setDescription( $item->{description} );
      $menu->addMenuItem($menuItem);
    }
  }
  
  foreach my $removeId (keys %idsToRemove) {
    debug "Delete from $removeId from menu";
    $menu->removeMenuItemById($removeId);
  }

  $menu->save();
  print "<script>top.reloadTreeFolder(".$menu->getMetaParentId().")</script>";
  $obj->_edit($menu);
}
#------------------------------------------------------------------
1;
