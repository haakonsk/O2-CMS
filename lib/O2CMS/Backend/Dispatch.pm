package O2CMS::Backend::Dispatch;

use strict;

use base 'O2::Dispatch';

#------------------------------------------------------------------
sub getSession {
  return $O2::Dispatch::context->getSingleton('O2CMS::Backend::Session');
}
#------------------------------------------------------------------
sub getNonGuiDispatchers {
  return ();
}
#------------------------------------------------------------------------------------------------------------
sub getDefaultClassAndMethod {
  return ('System::Login', 'displayLogin') unless $O2::Dispatch::context->getSession()->isLoggedIn();
  return ('System::Framework', 'setupFramework');
}
#------------------------------------------------------------------------------------------------------------
sub handlePublisherUrls {
  my ($obj, $url, $class, $method, %params) = @_;
  return ($class, $method);
}
#------------------------------------------------------------------------------------------------------------
1;
