package O2CMS::Backend::Gui::Statistics::GoogleAnalytics;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#----------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my ($email, $password) = $obj->_getAccountDetails();
  if ($email) {
    $obj->login();
  }
  else {
    $obj->editAccount();
  }
}
#----------------------------------------------------------------------
sub editAccount {
  my ($obj) = @_;
  my $account;
  if ($obj->getParam('objectId')) {
    # Editing an existing account
    $account = $context->getObjectById( $obj->getParam('objectId') );
    $cgi->setParam( 'parentId', $context->getObjectById( $obj->getParam('objectId') )->getMetaParentId() );
  }
  $obj->display(
    'editAccount.html',
    account => $account,
  );
}
#----------------------------------------------------------------------
sub saveAccountSettings {
  my ($obj) = @_;
  my %q = $obj->getParams();

  my $account;
  if (!$q{objectId}) {
    require O2CMS::Mgr::Statistics::GoogleAnalyticsManager;
    my $googleAnalyticsMgr = O2CMS::Mgr::Statistics::GoogleAnalyticsManager->new();
    $account = $googleAnalyticsMgr->newObject();
    $account->setMetaName(     'Google Analytics' );
    $account->setMetaParentId( $q{parentId}       );
  }
  else {
    $account = $obj->_getAccount( $q{accountId} );
  }

  $account->setEmail(       $q{email}      );
  $account->setPassword(    $q{password1}  ) if $q{password1};
  $account->setJavascript(  $q{javascript} );
  $account->save();
  return 1;
}
#----------------------------------------------------------------------
sub chooseAccount {
  my ($obj) = @_;
  my @accounts = $context->getSingleton('O2CMS::Mgr::Statistics::GoogleAnalyticsManager')->getAllAccounts();
  if (scalar @accounts == 1) {
    $obj->login( $accounts[0]->getId() );
  }
  elsif (scalar @accounts == 0) {
    $obj->display('accountNotRegistered.html');
  }
  else {
    $obj->display(
      'chooseAccount.html',
      accounts => \@accounts,
    );
  }
}
#----------------------------------------------------------------------
sub login {
  my ($obj, $accountId) = @_;
  $accountId ||= $obj->getParam('objectId');
  my ($email, $password) = $obj->_getAccountDetails( $accountId );
  $obj->display(
    'login.html',
    email    => $email,
    password => $password,
  );
}
#----------------------------------------------------------------------
sub _getAccount {
  my ($obj, $accountId) = @_;
  return $context->getObjectById($accountId) if $accountId;
  require O2CMS::Mgr::Statistics::GoogleAnalyticsManager;
  my $analyticsAccountMgr = O2CMS::Mgr::Statistics::GoogleAnalyticsManager->new();
  return $analyticsAccountMgr->getAccount();
}
#----------------------------------------------------------------------
sub _getAccountDetails {
  my ($obj, $accountId) = @_;
  my $account = $obj->_getAccount($accountId);
  return ( $account->getEmail(),  $account->getPassword(),  $account->getAnalyticsId() );
}
#----------------------------------------------------------------------
1;
