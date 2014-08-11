package O2CMS::Template::Taglibs::O2CMS::Html::StartMenu;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my ($obj, %tags) = $package->SUPER::register(%params);
  
  %tags = (
    %tags,
    StartMenu => 'prefix',
  );

  return ($obj, %tags);
}
#--------------------------------------------------------------------------------------------
sub StartMenu {
  my ($obj, %params) = @_;
  my $relativePath = '/etc/conf/startMenu.conf';
  my $customerMenuStruct;
  my $menuStruct      = do $context->getCmsPath()      . $relativePath;
  $customerMenuStruct = do $context->getCustomerPath() . $relativePath if -e $context->getCustomerPath() . $relativePath;
  
  my @pluginMenuStructs;
  foreach my $plugin (reverse $context->getPlugins()) {
    next if $plugin->{root} eq $context->getCmsPath();
    
    my $pluginConfPath = "$plugin->{root}/$relativePath";
    unshift @{$menuStruct}, do $pluginConfPath if -e $pluginConfPath && $plugin->{enabled};
  }
  
  unshift @{$menuStruct}, $customerMenuStruct if ref $customerMenuStruct eq 'HASH';
  return $obj->_buildMenu($menuStruct);
}
#--------------------------------------------------------------------------------------------
sub _buildMenu {
  my ($obj, $arrayRef, $level) = @_;
  my $html;
  $level ||= 0;
  my $space = '     ' x $level;
  foreach my $item (@{$arrayRef}) {
    $html .= $space . $obj->_buildMenuItem($item);
    $html .= $obj->_buildMenu( $item->{subMenus}, $level+1 ) if exists ($item->{subMenus})  &&  @{ $item->{subMenus} };
    $html .= "$space</o2:addMenuItem>\n";
  }
  return $html;
}
#--------------------------------------------------------------------------------------------
sub _buildMenuItem {
  my ($obj, $menuItem) = @_;
  my $name    = "\$lang->getString('$menuItem->{name}')";
  my $action  = '';
  my $dragId  = '';
  my $iconUrl = $menuItem->{icon};
  
  if ($menuItem->{action}) {
    $obj->{_menuItem}++;
    $dragId    = "startMenu_$obj->{_menuItem}";
    $iconUrl   = $context->getSingleton('O2::Image::IconManager')->getIconUrl( $menuItem->{iconClass}, 24 ) if $menuItem->{iconClass};
    $iconUrl ||= $menuItem->{icon};
    $action
      = exists $menuItem->{popupWindow}
      ? "top.openInWindow({ url : '$menuItem->{action}', width : '$menuItem->{popupWindow}->{width}', height : '$menuItem->{popupWindow}->{height}' }, '$iconUrl', '$name' )"
      : "top.openInFrame( '$menuItem->{action}','$iconUrl','$name' );"
      ;
  }
  
  return qq{<o2 addMenuItem name="$name" icon="$iconUrl" action="$action" dragId="$dragId">\n};
}
#--------------------------------------------------------------------------------------------
1;
