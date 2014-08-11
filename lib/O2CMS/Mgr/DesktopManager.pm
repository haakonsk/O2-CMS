package O2CMS::Mgr::DesktopManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2 qw($context $db);
use O2CMS::Obj::Desktop;

#--------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Desktop',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    layoutMode => { type => 'varchar', length => 255                        }, # values 'userLayout', 'flowLayout'
    sortBy     => { type => 'varchar', length => 32, defaultValue => 'auto' }, # values 'userLayout', auto,date,name,type
    iconSize   => { type => 'int', defaultValue => 24                       }, # values 16,24,32
    wallPaper  => { type => 'varchar', length => 255                        }, # url to a wallpaper image
    wallColor  => { type => 'varchar', length => 7                          }, # hex color code
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------
sub userIdHasDesktop {
  my ($obj, $userId) = @_;
  return $db->fetch("select objectId from O2_OBJ_OBJECT where ownerId = ? and className = 'O2CMS::Obj::Desktop' and status = 'active'", $userId);
}
#--------------------------------------------------------------------
sub setupNewDesktopForUserId {
  my ($obj, $userId) = @_;
  my $desktop = $obj->newObject();
  $desktop->setMetaName(    'Desktop object for userId: ' . $userId );
  $desktop->setMetaStatus(  'active'                                );
  $desktop->setMetaOwnerId( $userId                                 );
  $desktop->setWallColor(   '#FFFFFF'                               );
  $desktop->setLayoutMode(  'flowLayout'                            );
  $obj->save($desktop);
  return $desktop;
}
#--------------------------------------------------------------------
sub getDesktopByUserId {
  my ($obj, $userId) = @_;
  my $desktopId = $obj->userIdHasDesktop($userId);
  return $context->getObjectById($desktopId);
}
#--------------------------------------------------------------------
sub getDesktopByUser {
  my ($obj, $user) = @_;
  return $obj->getDesktopByUser( $user->getId() );
}
#--------------------------------------------------------------------
sub getDesktopItems {
  my ($obj, $desktop) = @_;
  
}
#--------------------------------------------------------------------
sub verifyDesktopItemName {
  my ($obj, $item) = @_;
 
  my @shortcuts = $db->fetchAll(
    "select objectId,name from O2_OBJ_OBJECT where name like ? and className = ? and ownerId = ? and status = 'active'",
    $item->getMetaName() . '%', $item->getMetaClassName(), $item->getMetaOwnerId()
  );
  my $cnt = 0;
  foreach my $shortcut (@shortcuts) {
    my $regExp = $item->getMetaName() . '\s*?\d*?';
    if ( $shortcut->{name} =~ m/$regExp/ ) {
      $cnt = $shortcut->{name} =~ m{ \( (\d+) \) }xms  ?  $1  :  $cnt+1;
    }
  }
  $item->setMetaName( $item->getMetaName() . ' (' . ($cnt+1) . ')' ) if $cnt;
  return $item;
}
#--------------------------------------------------------------------
1;
