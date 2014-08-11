package O2CMS::Backend::Session::Files;

use strict;

use base 'O2::HttpSession::Files';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------------
sub createObject {
  my ($package, %params) = @_;
  return $package->SUPER::createObject(sessionName => 'backend', %params);
}
#--------------------------------------------------------------------------------------------------
sub getNeedAuthRedirectUrl {
  return '/o2cms/System-Login/displayLogin';
}
#--------------------------------------------------------------------------------------------------
sub getCookieName {
  return $config->get('session.backend.cookieName');
}
#--------------------------------------------------------------------------------------------------
sub getSessionRoot {
  return $config->get('session.backend.sessionRoot');
}
#--------------------------------------------------------------------------------------------------
sub getPublicSessionRoot {
  return $config->get('session.backend.publicSessionRoot');
}
#--------------------------------------------------------------------------------------------------
sub isFrontend {
  return 0;
}
#--------------------------------------------------------------------------------------------------
1;
