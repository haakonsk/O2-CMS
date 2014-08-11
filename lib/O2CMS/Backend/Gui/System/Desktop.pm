package O2CMS::Backend::Gui::System::Desktop;

# Desktop Wall (the actuall desktop) for O2 Desktop

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  my $obj = $pkg->SUPER::new(%params);
  $obj->{desktopMgr}  = $context->getSingleton( 'O2CMS::Mgr::DesktopManager'           );
  $obj->{widgetMgr}   = $context->getSingleton( 'O2CMS::Mgr::Desktop::WidgetManager'   );
  $obj->{shortcutMgr} = $context->getSingleton( 'O2CMS::Mgr::Desktop::ShortcutManager' );
  return $obj;
}
#---------------------------------------------------------------------------------------
sub showDesktop { 
  my ($obj) = @_;
  my $userId = $context->getUserId();
  my $desktop;
  if (!$obj->{desktopMgr}->userIdHasDesktop($userId)) {
    $desktop = $obj->{desktopMgr}->setupNewDesktopForUserId($userId);

    # nilschd if we want some widgets to be installed per default for new users, this is the place to do it.
    # look at the sample code below
#    my $widget = $obj->{widgetMgr}->newObject();
#    $widget->setMetaName("Notes");
#    $widget->setMetaStatus('active');
#    $widget->setWidgetUrl('/o2cms/Widget-Notes/');
#    $widget->save();
#    $desktop->addDesktopItem($widget);
  }
  else {
    $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
  }
  $obj->display(
    'showDesktop.html',
    desktop => $desktop,
  );
}
#---------------------------------------------------------------------------------------
sub relocateShortcut {
  my ($obj) = @_;
  my %data = $obj->getParams();
  if ($data{shortcutId} && $data{newX} && $data{newY}) {
    # first we need to set Layout mode to userLayout if user wants manually place the icons
    my $userId = $context->getUserId();
    my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
    $desktop->setLayoutMode('userLayout');
    $desktop->save();
 
    my $shortCut = $context->getObjectById( $data{shortcutId} );
    if ($shortCut) {
      $shortCut->setXPosition( $data{newX} );
      $shortCut->setYPosition( $data{newY} );
      $shortCut->save();
      return 1;
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub saveNewShortcutName {
  my ($obj) = @_;
  my %data = $obj->getParams();
  if ($data{shortcutId} && $data{shortcutName}) {
    my $shortCut = $context->getObjectById( $data{shortcutId} );
    if ($shortCut){
      $data{shortcutName} =~ s/\s+/ /g;
      $data{shortcutName} =~ s/\t+/ /g;
      $data{shortcutName} =~ s/\n+/ /g;
      $shortCut->setMetaName( $data{shortcutName} );
      $shortCut->save();
      return 1;
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub addShortcut {
  my ($obj, $data) = @_;
  my %data = $data ? %{$data} : $obj->getParams();

  my $userId   = $context->getUserId();
  my $desktop  = $obj->{desktopMgr}->getDesktopByUserId($userId);
  my $shortcut = $obj->{shortcutMgr}->newObject();
  
  if ($data{action}) {
    $shortcut->setAction( $data{action} );
  }
  elsif ($data{id} && $data{className} && $data{name}) {
    $shortcut->setAction("top.openObject('$data{className}','$data{id}','$data{name}');");
  }
  # testing to see if this is a menuItem from startMenu
  if ( $data{id} =~ m/^startMenu\_\d+$/ ) {
    $data{action}  =~ m/.+\'([^\']+)\'\)\;$/i;
    $data{name}    = $1;
    $data{iconUrl} =~ s|\d+\.(\w\w\w)$|48\.$1|i;

  }
  # testing to see of this a "new" shorcut from the popup menu
  elsif( $data{id} =~ m/^newAction\:\:(.+?)\:\:(\d+)$/) {
    my $newObjectType     = $1;
    my $newObjectParentId = $2;
    return 0 unless $newObjectType && $newObjectParentId;
    my $o2Obj = $context->getObjectById($newObjectParentId);
    my $lang  = $context->getLang();
    my $classMetaName = $lang->getString("o2.className.$newObjectType");
    $data{name} = $lang->getString( 'o2.desktop.shortcutLabels.newObjectInParent', objectName => $classMetaName, parentName => $o2Obj->getMetaName() );
    # XXX we might want to have an different icon for "New objects"
    $data{iconUrl} =~ s|\d+\.(\w\w\w)$|48\.$1|i;
  }
  elsif ( $data{id} =~ m/^\d+$/ ) { # is an O2_Obj
    my $o2Obj = $context->getObjectById( $data{id} );
    if ($o2Obj && $o2Obj->isa('O2::Obj::Object')) {
      $data{iconUrl} = $o2Obj->getIconUrl(48);
    }
  }
  else {
    $data{iconUrl} =~ s|\d+\.(\w\w\w)$|48\.$1|i;
  }

  $shortcut->setMetaOwnerId( $context->getUserId() );
  $shortcut->setMetaName(    $data{name}           );
  $shortcut->setImageUrl(    $data{iconUrl}        );
  $shortcut->setXPosition(   $data{xPosition}      );
  $shortcut->setYPosition(   $data{yPosition}      );
  $shortcut->setMetaStatus(  'active'              );

  # we checks if user has others shortcuts with same name, if yes then e.g 'Frontpage' will become 'Frontpage (2)'
  $obj->{desktopMgr}->verifyDesktopItemName($shortcut);

  $shortcut->save();
  $desktop->addDesktopItem($shortcut);
  return {
    newShortcutId => $shortcut->getId(),
    iconUrl       => $data{iconUrl},
    createTime    => $shortcut->getMetaCreateTime,
    action        => $shortcut->getAction(),
    name          => $shortcut->getMetaName(),
  };
}
#---------------------------------------------------------------------------------------
sub deleteShortcut {
  my ($obj) = @_;
  my %data = $obj->getParams();
  if ($data{shortcutId}) {
    my $shortCut = $context->getObjectById( $data{shortcutId} );
    if ($shortCut){
      $shortCut->deletePermanently();
      return 1;
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub saveDesktopSettings {
  my ($obj) = @_;
  my %data = $obj->getParams();
  my $userId  = $context->getUserId();
  my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);

  $desktop->setLayoutMode( $data{layoutMode} ) if $data{layoutMode};
  $desktop->setSortBy(     $data{orderBy}    ) if $data{orderBy};
  $desktop->setWallColor(  $data{wallColor}  ) if $data{wallColor};
  $desktop->setWallPaper(  $data{wallPaper}  ) if $data{wallPaper};
  $desktop->setIconSize(   $data{iconSize}   ) if $data{iconSize};
  $desktop->save();
  return 1;
}
#---------------------------------------------------------------------------------------
# Widgets method
#---------------------------------------------------------------------------------------
sub showWidget {
  my ($obj) = @_;
  my %data = $obj->getParams();

  if ( $data{widgetId} ) {
    my $userId  = $context->getUserId();
    my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
    my $widget  = $context->getObjectById( $data{widgetId} );

    if ($widget) {
      $widget->setIsMinimized(0);
      $widget->save();
      my $shortCut = $context->getObjectById( $data{shortcutId} );
      if ($shortCut) {
        $shortCut->deletePermanently();
        return {
          widgetId   => $widget->getId(),
          shortcutId => $shortCut->getId(),
        };
      }
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub deleteWidget {
  my ($obj) = @_;
  my %data = $obj->getParams();
  if ( $data{widgetId} ) {
    my $widget = $context->getObjectById( $data{widgetId} );
    $widget->deletePermanently();
    return {
      widgetId => $data{widgetId},
    };
  }
  return 0;
}
#---------------------------------------------------------------------------------------
# 1: hide the widget on client side
# 2: set status to minimized in DB
# 3. setup a new shortcut to represent the minimized widget
# 4. return that
sub minimizeWidget {
  my ($obj) = @_;
  my %data = $obj->getParams();

  if ( $data{widgetId} ) {
    my $userId  = $context->getUserId();
    my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
    my $widget  = $context->getObjectById( $data{widgetId} );
    if ($widget) {
      $widget->setIsMinimized(1);
      $widget->save();

      my $shortcut = $obj->{shortcutMgr}->newObject();
      
      $shortcut->setAction(     "desktop.showWidget('" . $widget->getId() . "');" );
      $shortcut->setMetaName(   $widget->getMetaName()                            );
      $shortcut->setImageUrl(   $widget->getImageUrl(32)                          );
      $shortcut->setXPosition(  $widget->getXPosition()                           );
      $shortcut->setYPosition(  $widget->getYPosition()                           );
      $shortcut->setMetaStatus( 'active'                                          );
      $shortcut->save();
      $shortcut->setAction( "desktop.showWidget('" . $widget->getId() . "','" . $shortcut->getId() . "');" );
      $shortcut->save();
      $desktop->addDesktopItem($shortcut);
      return {
        newShortcutId => $shortcut->getId(),
        iconUrl       => $shortcut->getImageUrl(),
        createTime    => $shortcut->getMetaCreateTime,
        action        => $shortcut->getAction, 
        name          => $shortcut->getMetaName,
        widgetId      => $widget->getId(),
        xPosition     => $shortcut->getXPosition,
        yPosition     => $shortcut->getYPosition,
      };
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub saveWidgetSettings {
  my ($obj) = @_;
  my %data = $obj->getParams();

  if ( $data{widgetId} ) {
    my $widget;
    eval {
      $widget = $context->getObjectById( $data{widgetId} );
    };
    return 1 if $@;

    if ($widget) {
      $widget->setXPosition(   $data{newX}                ) if exists $data{newX};
      $widget->setYPosition(   $data{newY}                ) if exists $data{newY};
      $widget->setIsMinimized( $data{isMinimized} ? 1 : 0 ) if exists $data{isMinimized};
      $widget->save();
      return 1;
    }
    
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub saveWidget {
  my ($obj) = @_;
  my %data = $obj->getParams();

  my $widget;
  if ( $data{widgetId} ) {
    $widget = $context->getObjectById( $data{widgetId} );
  }
  else {
    $widget = $obj->{widgetMgr}->newObject();
  }
  $widget->setMetaName(   $data{widgetName}      );
  $widget->setWidgetUrl(  $data{widgetCodeOrUrl} ) if $data{widgetSrc} eq 'url';
  $widget->setWidgetCode( $data{widgetCodeOrUrl} ) if $data{widgetSrc} eq 'code';
  $widget->save();

  my $userId  = $context->getUserId();
  my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
  $desktop->addDesktopItem($widget);
  print "<html><body><script type='text/javascript'>this.window.parent.location.href=this.window.parent.location.href;</script></body></html>";
}
#---------------------------------------------------------------------------------------
sub editWidget {
  my ($obj) = @_;
  $obj->display('editWidget.html');
}
#---------------------------------------------------------------------------------------
sub removeWidget {
  my ($obj) = @_;
  my %data = $obj->getParams();
  if ( $data{widgetId} ) {
    my $userId  = $context->getUserId();
    my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
    my $widget  = $context->getObjectById( $data{widgetId} );

    if ($widget) {
      my $status = $widget->deletePermanently();      
      return {
        status => $status,
      };
    }
  }
  return 0;
}
#---------------------------------------------------------------------------------------
sub addWidget {
  my ($obj) = @_;
  my $pseudoWidgetId = $obj->getParam('pseudoWidgetId');
  return $obj->ajaxError("Wrong pseudo widget ID: $pseudoWidgetId (must be a number)") if $pseudoWidgetId !~ m/^\d+$/;
  
  my $userId  = $context->getUserId();
  my $desktop = $obj->{desktopMgr}->getDesktopByUserId($userId);
  my $widgets = $obj->{widgetMgr}->getAvailableWidgets();
  
  my $widgetConf = $widgets->[$pseudoWidgetId];
  my $widget = $obj->{widgetMgr}->newObject();
  $widget->setMetaName( $widgetConf->{name} );
  $widget->setMetaStatus('active');
  if ( $widgetConf->{widgetUrl} ) {
    $widget->setWidgetUrl( $widgetConf->{widgetUrl} );
  }
  else {
    $widget->setWidgetCode( $widgetConf->{widgetCode} );
  }
  $widget->setHeight(     $widgetConf->{height}          );
  $widget->setWidth(      $widgetConf->{width}           );
  $widget->setResizeable( $widgetConf->{resizeable}      );
  $widget->setXPosition(  $widgetConf->{xPosition} || 20 );
  $widget->setYPosition(  $widgetConf->{yPosition} || 20 );
  
  my $imageUrl
    = $widgetConf->{className}
    ? $context->getSingleton('O2::Image::IconManager')->getIconUrl( $widgetConf->{className}, 48 )
    : $widgetConf->{iconUrl}
    ;
  $widget->setImageUrl($imageUrl);
  $widget->save();
  $desktop->addDesktopItem($widget);
  
  return {
    widgetId     => $widget->getId(), 
    height       => $widget->getHeight(),
    width        => $widget->getWidth(),
    widgetUrl    => $widget->getWidgetUrl(),
    xPosition    => $widget->getXPosition(),
    yPosition    => $widget->getYPosition(),
    isResizeable => $widget->getResizeable(),
  };
}
#---------------------------------------------------------------------------------------
sub listWidgets {
  my ($obj) = @_;
  my $desktop = $obj->{desktopMgr}->getDesktopByUserId( $context->getUserId() );
  my %desktopItems = map { $_->getWidgetUrl => 1 } grep { $_->getMetaClassName() eq 'O2CMS::Obj::Desktop::Widget' } $desktop->getDesktopItems();
  
  $obj->display(
    'listWidgets.html', 
    widgets       => $obj->{widgetMgr}->getAvailableWidgets(),
    userHasWidget => \%desktopItems,
  );
}
#---------------------------------------------------------------------------------------
sub test {
  my ($obj) = @_;
  my $shortcut = $obj->{shortcutMgr}->newObject();
  $shortcut->setMetaOwnerId( $context->getUserId() );
  $shortcut->setMetaName('frontpage');
  print "<li>".$obj->{desktopMgr}->verifyDesktopItemName($shortcut)->getMetaName();
}
#---------------------------------------------------------------------------------------
1;
