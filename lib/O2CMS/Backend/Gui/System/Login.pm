package O2CMS::Backend::Gui::System::Login;

use strict;

use base 'O2CMS::Backend::Gui';
use base 'O2::Role::Misc::Login';

use O2 qw($context $config);

#---------------------------------------------------------------------------------------
sub needsAuthentication {
  return 0;
}
#---------------------------------------------------------------------------------------
sub displayLogin {
  my ($obj, @params) = @_;
  my $testPath    = $config->get('o2.session.path') . "/writeTest.txt";
  my $testContent = __PACKAGE__ . ': Test to see if session is writable. Time now is ' . time;
  
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->writeFile($testPath, $testContent);
  print "Could not write to $testPath" if $fileMgr->getFile($testPath) ne $testContent;
  
  $obj->display('displayLogin.html', @params);
}
#---------------------------------------------------------------------------------------
sub logoutSuccess {
  my ($obj) = @_;
  $obj->displayLogin( message => 'userLoggedOut' );
}
#---------------------------------------------------------------------------------------
1;
