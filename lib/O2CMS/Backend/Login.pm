package O2CMS::Backend::Login;

use strict;

use O2 qw($context);

#---------------------------------------------------------------------------------
sub login {
  my ($pkg, %params) = @_;
  my $user = $context->getSingleton('O2CMS::Mgr::AdminUserManager')->getUserByUsername( $params{username} );
  return     if !$user || $user->getUsername() ne $params{username};
  return unless $user->isCorrectPassword( $params{password} );
  return     if $user->getMetaStatus() ne 'active';
  return $user;
}
#---------------------------------------------------------------------------------
1;
