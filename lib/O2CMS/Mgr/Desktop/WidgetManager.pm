package O2CMS::Mgr::Desktop::WidgetManager;

use strict;

use base 'O2CMS::Mgr::Desktop::ItemManager';

use O2 qw($context $config);
use O2CMS::Obj::Desktop::Widget;

#--------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Desktop::Widget',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    widgetUrl   => { type => 'varchar', length => 255   },
    height      => { type => 'int', defaultValue => 250 },
    width       => { type => 'int', defaultValue => 250 },
    resizeable  => { type => 'int', defaultValue => 0   },
    isMinimized => { type => 'int', defaultValue => 0   },
    widgetCode  => { type => 'text', defaultValue => '' },
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  my $widget = $context->getObjectById($objectId);
  my $widgetUrl = $widget->getWidgetUrl();
  if ($widgetUrl) {
    my $widgetObject = $obj->_getGuiObjectForWidgetUrl($widgetUrl);
    $widgetObject->deletePermanently($objectId) if $widgetObject;
  }
  return $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#--------------------------------------------------------------------
sub getAvailableWidgets {
  my ($obj) = @_;
  my $widgets = $config->get('installedWidgets');
  return wantarray ? @{$widgets} : $widgets;
}
#--------------------------------------------------------------------
sub _getGuiObjectForWidgetUrl {
  my ($obj, $widgetUrl) = @_;
  if ($widgetUrl =~ m|.*\/o2cms\/([a-zA-Z0-9\_\-]+)\/?|) {
    my $class = $1;
    if ($class) {
      $class =~ s/\-/\:\:/g;
      $class = "O2CMS::Backend::Gui::$class" if $class;
      
      my $object;
      eval "require $class;";
      die "Could not load class '$class': $@" if $@;
      
      $object = $class->new();
      die "Widget $object is not a valid Wigdet" unless $object->isa('O2CMS::Backend::Gui::Widget');
      
      return $object;
    }
  }
  return undef;
}
#--------------------------------------------------------------------
1;
