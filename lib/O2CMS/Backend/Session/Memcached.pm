package O2CMS::Backend::Session::Memcached;

use strict;

use base 'O2::HttpSession::Memcached';

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
sub isFrontend {
  return 0;
}
#--------------------------------------------------------------------------------------------------
1;
