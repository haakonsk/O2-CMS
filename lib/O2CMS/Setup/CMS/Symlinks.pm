package O2::Setup::CMS::Symlinks;

use strict;

use base 'O2::Setup::CMS';

use O2 qw($context);

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  my $customerRoot = $context->getEnv( 'O2CUSTOMERROOT' );
  my $o2Root       = $context->getEnv( 'O2ROOT'         );
  foreach my $path ($obj->getSymlinks()) {
    system "ln -s $o2Root/$path $customerRoot/$path";
  }
  return 1;  
}
#---------------------------------------------------------------------
sub getSymlinks {
  my ($obj) = @_;
  return (
    'var/www/js/util/date.js',
    'var/www/js/jquery.js',
    'var/www/js/jquery-ui.js',
  );
}
#---------------------------------------------------------------------
sub upgrade {
  return 1;
}
#---------------------------------------------------------------------
sub remove {
  return 1;
}
#---------------------------------------------------------------------
sub backup {
  return 1;
}
#---------------------------------------------------------------------
1;
