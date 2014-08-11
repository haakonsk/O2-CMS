package O2CMS::OS::Process;

# OS independent process handling, very simple at the current stage. This module is just a "proxy" class.

use strict;

#------------------------------------------------------------
sub new {
  my ($package) = @_;

  if ($ENV{OS} eq 'Windows_NT') { # windows system?
    require O2CMS::OS::Win32::Process;
    return O2CMS::OS::Win32::Process->new();
  }
  require O2CMS::OS::Linux::Process;
  return O2CMS::OS::Linux::Process->new();
#  return bless {}, $package;
}
#------------------------------------------------------------
1;
