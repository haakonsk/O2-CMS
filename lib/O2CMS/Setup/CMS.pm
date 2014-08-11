package O2CMS::Setup::CMS;

# This is just a common file to make sure we do everything in the right order. We're also able to
# setup anything we want in advance here.

use strict;

use base 'O2::Setup';

use constant callerSubIndex => 3;

use O2 qw($context);

#---------------------------------------------------------------------
# sub install is inherited and only returns true as this module's only a
# way to ensure that we do everything in the right order - se getPrequisities 
#---------------------------------------------------------------------
sub backup {
  my ($obj) = @_;
  return 1;
}
#---------------------------------------------------------------------
sub getDependencies {
  my ($obj) = @_;
  return if ref $obj ne 'O2CMS::Setup::CMS'; # XXX Need to figure out a way to prevent subclasses from installing on their own
  
  my $setupConf = $obj->getSetupConf();
  $setupConf->{dbpassword} ||= $context->getSingleton('O2::Util::Password')->generatePassword(8);
  
  return qw(
    O2::Setup::Directories
    O2CMS::Setup::CMS::Directories
    O2::Setup::Configs
    O2CMS::Setup::CMS::Configs
    O2::Setup::Database
    O2::Setup::Apache
    O2::Setup::Classes
    O2::Setup::Scripts::Standard
    O2::Setup::ClassesAndDefaults
    O2CMS::Setup::CMS::ClassesAndDefaults
    O2::Setup::Cron
    O2::Setup::Test
    O2::Setup::Cleanup
  );
}
#---------------------------------------------------------------------
sub notImplemented {
  my ($obj) = @_;
  my ($methodName) = (caller 1)[callerSubIndex] =~ m/::(\w+)$/s;
  die "Sorry " . ref ($obj) . " currently has no support for '$methodName'.\n";
}
#---------------------------------------------------------------------
1;
