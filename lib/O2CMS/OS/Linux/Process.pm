package O2CMS::OS::Linux::Process;

# The process handling for linux system this one is a bit 'hacky', cause it uses perl kill

use strict;

#--------------------------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  return {}, $package;
}
#--------------------------------------------------------------------------------------------
sub getProcessInformation {
  my ($obj, $pid) = @_;
#  my $pi = Win32::Process::Info->new ();  
}
#--------------------------------------------------------------------------------------------
sub isAlive {
  my ($obj, $pid) = @_;
  return 0 unless $pid;
  return kill 0, $pid; # checks if this process is alive
}
#--------------------------------------------------------------------------------------------
sub killProcess {
  my ($obj, $pid, $exitCode) = @_;
  return 0 unless $pid;
  return kill 9, $pid;
}
#--------------------------------------------------------------------------------------------
1;
