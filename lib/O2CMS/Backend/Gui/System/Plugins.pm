package O2CMS::Backend::Gui::System::Plugins;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#---------------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my @plugins = $context->getPlugins();
  $obj->display(
    'init.html',
    plugins => \@plugins,
  );
}
#---------------------------------------------------------------------------------------
sub toggleEnabled {
  my ($obj) = @_;
  my $pluginName = $obj->getParam('pluginName');
  
  $context->toggleEnablePlugin($pluginName);
  
  $obj->display(
    'includes/enabledIcon.html',
    plugin => $context->getPlugin($pluginName),
  );
}
#---------------------------------------------------------------------------------------
sub saveNewPluginOrder {
  my ($obj) = @_;
  my @pluginNames = $obj->getParam('newRowOrderForTable_plugins');
  if (@pluginNames) {
    my @plugins;
    foreach my $pluginName (@pluginNames) {
      $pluginName =~ s{ \A plugin_ }{}xms;
      push @plugins, $context->getPlugin($pluginName);
    }
    push @plugins, $context->getPlugin('CMS');
    $context->getSingleton('O2::Data')->save( $context->getCustomerPath() . '/etc/conf/plugins.conf', \@plugins );
  }
  $cgi->redirect(
    setMethod    => 'init',
    removeParams => 1,
  );
}
#---------------------------------------------------------------------------------------
sub saveNewPlugin {
  my ($obj) = @_;
  my @plugins;
  foreach my $plugin ($context->getPlugins()) {
    if ($plugin->{name} eq 'CMS') {
      push @plugins, {
        name    => $obj->getParam('name'),
        root    => $obj->getParam('path'),
        enabled => 1,
      };
    }
    push @plugins, $plugin;
  }
  $context->getSingleton('O2::Data')->save( $context->getCustomerPath() . '/etc/conf/plugins.conf', \@plugins );
  $cgi->redirect( setMethod => 'init' );
}
#---------------------------------------------------------------------------------------
1;
