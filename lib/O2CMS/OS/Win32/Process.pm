package O2CMS::OS::Win32::Process;

# The process handling for win32 system

use strict;

use Win32::Process::Info;

#--------------------------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  return {}, $package;
}
#--------------------------------------------------------------------------------------------
sub getProcessInformation {
  my ($obj, $pid) = @_;
  my $pi = Win32::Process::Info->new();  
}
#--------------------------------------------------------------------------------------------
sub isAlive {
  my ($obj, $pid) = @_;
  my $pi = Win32::Process::Info->new();  
  my %pids = map { $_ => 1 } $pi->ListPids();
  return exists $pids{$pid};
}
#--------------------------------------------------------------------------------------------
sub killProcess {
  my ($obj, $pid, $exitCode) = @_;
  require Win32::Process;
  return Win32::Process::KillProcess($pid, $exitCode);
}
#--------------------------------------------------------------------------------------------
1;
