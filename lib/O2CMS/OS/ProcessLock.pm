package O2CMS::OS::ProcessLock;

# Provides you with OS independent interface to create lockfiles for processes. E.g. a LP parser for a customer

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg,%init)=@_;
  
  if(!-d $init{lockFilePath} || !-w $init{lockFilePath}) {
    die "Need a valid lockFilePath for the lock file(s)";
  }
  $init{lockFileExtension}||='.processLock';
  
  return bless \%init, $pkg;
}
#------------------------------------------------------------
sub lock {
  my ($obj,$processName)=@_;
  
  if(!$processName) {
    die __PACKAGE__.": processName is missing";
  }

  if($obj->isLocked($processName)) {
    die __PACKAGE__.": Process with name '$processName' is locked";
  }

  my $lockFile = $obj->{lockFilePath}.'/'.$processName.$obj->{lockFileExtension};

  my $time=scalar localtime;
  my $epochtime=time;
  local *FH;
  open (FH, ">$lockFile") || die __PACKAGE__.": Could not create '$lockFile' reason: $@";
  print FH "{
   pid     => $$,
   startup => '$time',
   epoch => $epochtime,
   cmd => '".$0.' '.join(' ',@ARGV)."',
   user => '$ENV{USER} ($ENV{UID})',
 };";
  close (FH);
  return 1;
}
#------------------------------------------------------------
sub unLock {
  my ($obj,$processName)=@_;
  my $lockFile = $obj->{lockFilePath}.'/'.$processName.$obj->{lockFileExtension};
  if($obj->isLocked($processName)) {
    unlink $lockFile || die __PACKAGE__.": Could not delete '$lockFile' reason: $@";
  }
}
#------------------------------------------------------------
sub isLocked {
  my ($obj,$processName)=@_;
  my $lockFile = $obj->{lockFilePath}.'/'.$processName.$obj->{lockFileExtension};
  return -e $lockFile;
}
#------------------------------------------------------------
sub isLockedAndAlive {
  my ($obj,$processName)=@_;
  my $lockData = $obj->_getLockData($processName);
  if($lockData && !$lockData->{pid}) {
    die __PACKAGE__.": Lockfile is corrupt reason: No pid found in lock file";
  }
  
  require O2CMS::OS::Process;
  my $ps = O2CMS::OS::Process->new();
  if($ps->isAlive($lockData->{pid})) {
    return 1;
  }
  else {
     $obj->unLock($processName);
   }
  return 0;
}
#------------------------------------------------------------
sub getLockTime {
  my ($obj,$processName)=@_;
  my $lockData = $obj->_getLockData($processName);
  return ($lockData->{epoch}||0);
}
#------------------------------------------------------------
sub getPID {
  my ($obj,$processName)=@_;
  my $lockData = $obj->_getLockData($processName);
  return ($lockData->{pid}||0);
}
#------------------------------------------------------------
sub _getLockData {
  my ($obj,$processName)=@_;
  
  my $lockFile = $obj->{lockFilePath}.'/'.$processName.$obj->{lockFileExtension};
  if($obj->isLocked($processName)) {
    my $lockData;
    eval {
      $lockData  = do $lockFile;
    };
    if($@) {
      die __PACKAGE__.": Lockfile is corrupt reason: $@";
    }
    return $lockData;
  }
  return undef;
}
#------------------------------------------------------------
1;
