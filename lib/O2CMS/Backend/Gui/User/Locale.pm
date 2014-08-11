package O2CMS::Backend::Gui::User::Locale;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $session);

#-----------------------------------------------------------------------------
sub setLocale {
  my ($obj) = @_;
  my $backendUser = $context->getUser();
  $backendUser->setAttribute( 'locale', $obj->getParam('locale') );
  $backendUser->save();
  
  return 1 if $obj->getParam('isAjaxRequest');
  
  my $url = $obj->getParam('url') || '/';
  $cgi->redirect($url);
}
#-----------------------------------------------------------------------------
sub setFrontendLocaleCode {
  my ($obj) = @_;
  my $user = $context->getUser();
  $user->setAttribute( 'frontendLocaleCode', $obj->getParam('localeCode') );
  $user->save();
  return 1;
}
#-----------------------------------------------------------------------------
1;
