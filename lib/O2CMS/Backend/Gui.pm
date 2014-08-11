package O2CMS::Backend::Gui;

use strict;

use base 'O2::Gui';

use O2 qw($context $config $cgi);

#------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  $params{lang} = $context->getLang(); # For backward compatibility..
  return bless \%params, $package; 
}
#------------------------------------------------------------------
sub needsAuthentication {
  return 1;
}
#------------------------------------------------------------------
sub authenticate {
  my ($obj, $method) = @_;
  return $context->getUserId() ? 1 : 0;
} 
#------------------------------------------------------------------
sub handleAuthenticationFailure {
  my ($obj, $method) = @_;
  return $obj->error('notLoggedIn') if $obj->getParam('isAjaxRequest');
  $cgi->redirect( $obj->getLoginUrl() );
}
#------------------------------------------------------------------
sub getLoginUrl {
  return $config->get('o2.adminRootUrl');
}
#------------------------------------------------------------------
sub error {
  my ($obj, @params) = @_;
  my $errorMsg = '<b>' . join ('<br>', @params) . "</b><br><br>\n" . $context->getConsole()->getStackTraceHtml();
  
  return $obj->ajaxError($errorMsg) if $obj->getParam('isAjaxRequest');
  
  $obj->display(
    'o2://var/templates/error.html',
    msg => $errorMsg,
  );
  $cgi->output();
  $cgi->exit();
}
#------------------------------------------------------------------
sub getIconUrl {
  my ($obj, $size) = @_;
  return $context->getSingleton('O2::Image::IconManager')->getIconUrl( ref $obj, $size || 16 );
}
#------------------------------------------------------------------
1;
