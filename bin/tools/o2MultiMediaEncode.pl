# This the cron job that fires up the encodeJobs method in the O2CMS::Mgr::MultiMedia::EncodeJobManager
#
# NOTE: I don't regard this a permanent solutions, as soon we get the O2 Schedueler up and running.
#       An entry there should replace this script allowing control from the O2 Backoffice/Dekstop
#       This script will not have any logging or similar

umask oct 2;

use O2 qw($context $config);

my $lockFileName = 'o2MultimediaEncoder';
my $tmpDir       = $config->get('setup.tmpDir');

lockEncoder();
$context->getSingleton('O2CMS::Mgr::MultiMedia::EncodeJobManager')->encodeJobs();
unlockEncoder();

sub lockEncoder {
  require O2CMS::OS::ProcessLock;
  my $lockHandler = O2CMS::OS::ProcessLock->new(lockFilePath => $tmpDir);
  
  if ($lockHandler->isLockedAndAlive($lockFileName)) {
    die "Encoder process is running with PID: " . $lockHandler->getPID($lockFileName) . " since " . scalar localtime ( $lockHandler->getLockTime($lockFileName) );
  }
  $lockHandler->lock($lockFileName);
  return 1;
}

sub unlockEncoder {
  require O2CMS::OS::ProcessLock;
  my $lockHandler = O2CMS::OS::ProcessLock->new(lockFilePath => $tmpDir);
  $lockHandler->unLock($lockFileName);
}
