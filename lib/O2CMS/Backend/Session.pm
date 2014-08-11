package O2CMS::Backend::Session;

use strict;

use constant DEBUG => 0;
use O2 qw($context $config);

#--------------------------------------------------------------------------------------------------
sub new {
  my ($package, $backendSessionId) = @_;
  my %params = $backendSessionId  ?  ( sessionId => $backendSessionId )  :  ();
  
  if ($config->get('session.dataStore') eq 'memcached' && $context->getMemcached()->isa('O2::Cache::MemcachedFast')) {
    require O2CMS::Backend::Session::Memcached;
    return O2CMS::Backend::Session::Memcached->createObject(%params);
  }
  
  require O2CMS::Backend::Session::Files;
  return O2CMS::Backend::Session::Files->createObject(%params);
}
#--------------------------------------------------------------------------------------------------
sub createObject {
  my ($package, %params) = @_;
  return $package->SUPER::new(%params);
}
#--------------------------------------------------------------------------------------------------
1;
