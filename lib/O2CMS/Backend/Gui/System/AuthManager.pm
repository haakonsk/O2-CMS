package O2CMS::Backend::Gui::System::AuthManager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------
sub init { 
  my ($obj) = @_;
  $obj->userAdm();
}
#---------------------------------------------------------------------------------
# User handling
#---------------------------------------------------------------------------------
sub userAdm {
  my ($obj, %params) = @_;
  $obj->display(
    'userAdministration.html',
    users => [ $context->getSingleton('O2CMS::Mgr::AdminUserManager')->getUsers() ],
  );
}
#---------------------------------------------------------------------------------
sub editUser {
  my ($obj, %params) = @_;
  my $userMgr = $context->getSingleton('O2CMS::Mgr::AdminUserManager');
  $obj->display(
    'editUser.html',
    user         => !$params{user} && $obj->getParam('userId')  ?  $context->getObjectById( $obj->getParam('userId') )  :  $userMgr->newObject(),
    errorMessage =>  $params{errMsg},
    message      =>  $params{message},
  );
}
#---------------------------------------------------------------------------------
sub saveUser {
  my ($obj) = @_;

  my $userMgr = $context->getSingleton('O2CMS::Mgr::AdminUserManager');

  my $user;
  if ($obj->getParam('userId') > 0) {
    $user = $context->getObjectById( $obj->getParam('userId') );
  }
  else {
    $user = $userMgr->newObject();
    $user->setUsername( $obj->getParam('username') );
  }
  $user->setFirstName( $obj->getParam('firstName') );
  $user->setLastName(  $obj->getParam('lastName')  );
  if ($obj->getParam('password') && $obj->getParam('password') eq $obj->getParam('password2')) {
    $user->setPassword( $obj->getParam('password') );
  }

  if ( $userMgr->getUserByUsername( $user->getUsername() ) && !$user->getId() ) {
    $obj->editUser(
      user   => $user,
      errMsg => $obj->getString( 'o2.authManager.errorMessages.userWithSuchUsernameExists', username => $user->getUsername() )
    );
  }
  else {
    my $message;
    $message = $obj->getString('o2.authManager.editUser.userIsSaved')        if $user->getId();
    $message = $obj->getString('o2.authManager.editUser.newUserIsSaved') unless $user->getId();

    $user->setMetaStatus( $obj->getParam('status') );
    $user = $user->save();

    $obj->editUser(
      user    => $user,
      message => $message,
    );
  }
}
#---------------------------------------------------------------------------------
1;
