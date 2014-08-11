package O2CMS::Backend::Gui::User::MemberManager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $session);

#--------------------------------------------------------------------------------------#
sub init {
  my ($obj) = @_;
  # Storing member statuses in session since the SQL for getting the distinct statuses might be slow (if there are many members)
  my $statuses = $session->get('memberStatuses');
  if (!$statuses) {
    $statuses = [ $context->getSingleton('O2::Mgr::MemberManager')->search()->getDistinct('metaStatus') ];
    $session->set('memberStatuses', $statuses);
  }
  
  $obj->display(
    'memberSearch.html',
    statuses    => $statuses,
    numStatuses => scalar @{$statuses},
  );
}
#--------------------------------------------------------------------------------------#
sub edit {
  my ($obj) = @_;
  $obj->display(
    'edit.html',
    member => $context->getObjectById( $obj->getParam('memberId') ),
  );
}
#--------------------------------------------------------------------------------------#
sub save {
  my ($obj) = @_;
  my %q = $obj->getParams();
  my $member = $context->getObjectById( $q{memberId} );
  die "No member with id " . $member->getId() if !$member || !$member->isa('O2::Obj::Member');
  
  $member->setEmail(      delete $q{email}      );
  $member->setFirstName(  delete $q{firstname}  );
  $member->setMiddleName( delete $q{middlename} );
  $member->setLastName(   delete $q{lastname}   );
  $member->setPassword(   delete $q{password}   );
  foreach my $param (keys %q) {
    my ($attributeName) = $param =~ m{ \A attribute_ (.+) \z }xms;
    next unless $attributeName;
    $member->setAttribute($attributeName, $q{$param});
  }
  $member->save();
  $obj->showMemberInfo( $member->getId() );
}
#--------------------------------------------------------------------------------------#
sub deactivate {
  my ($obj) = @_;
  my $member = $context->getObjectById( $obj->getParam('memberId') );
  if ($member->isa('O2::Obj::Member')) {
    $member->delete();
  }
  $obj->showMemberInfo( $member->getId() );
}
#--------------------------------------------------------------------------------------#
sub activate {
  my ($obj) = @_;
  my $member = $context->getObjectById( $obj->getParam('memberId') );
  if ($member->isa('O2::Obj::Member')) {
    $member->setMetaStatus('active');
    $member->save();
  }
  $obj->showMemberInfo( $member->getId() );
}
#--------------------------------------------------------------------------------------#
sub search {
  my ($obj) = @_;

  my %q = $obj->getParams();
  $q{-orderBy} = delete $q{orderBy} if $q{orderBy};

  # Making it possible to use * as wild card
  foreach my $fieldName (qw(firstname lastname username email)) {
    if ($q{$fieldName} =~ m{ \* }xms) {
      $q{$fieldName} = "like $q{$fieldName}";
      $q{$fieldName} =~ s{ \* }{%}xmsg;
    }
  }

  foreach my $fieldName (keys %q) {
    delete $q{$fieldName} unless $q{$fieldName};
  }
  $q{metaStatus} = delete $q{status} if $q{status};

  my $resultsPrPage = delete $q{resultsPrPage};
  my $page          = delete $q{page} || 1;

  $q{-orderBy} .= ' ' . delete $q{sortDirection} if $q{sortDirection};
  my $start = ($page-1) * $resultsPrPage;

  my $memberMgr = $context->getSingleton('O2::Mgr::MemberManager');
  my @members = $memberMgr->objectSearch(
    %q,
    -skip  => $start,
    -limit => $resultsPrPage,
  );

  my $isMoreMembers = %q && $resultsPrPage && $memberMgr->getTotalNumSearchResults() > $page * $resultsPrPage;

  $obj->display(
    'showMembers.html',
    members      => \@members,
    pageNum      => $page,
    previousPage => $page >= 2     ? $page-1 : 0,
    nextPage     => $isMoreMembers ? $page+1 : 0,
  );
}
#--------------------------------------------------------------------------------------#
sub showMemberInfo {
  my ($obj, $memberId) = @_;

  my %q   = $obj->getParams();

  $memberId   ||= $q{memberId};
  my $memberMgr = $context->getSingleton('O2::Mgr::MemberManager');
  my $member    = $context->getObjectById($memberId);

  # Find who this user can login on behalf as
  my @canLoginAsMembers;
  if (!$memberMgr->canLoginAsAll($memberId)) {
    my @canLoginAsUserIds = $memberMgr->getCanLoginAsUserIds($memberId);
    foreach my $id (@canLoginAsUserIds) {
      push @canLoginAsMembers, $context->getObjectById($id);
    }
  }

  $obj->display(
    'memberInfo.html',
    member            => $member,
    memberAttributes  => { $member->getAttributes() },
    canLoginAsMembers => $memberMgr->canLoginAsAll($memberId) ? 'all' : \@canLoginAsMembers,
  );
}
#--------------------------------------------------------------------------------------#
sub editUsername {
  my ($obj) = @_;
  $obj->display(
    'editUsername.html',
    member => $context->getSingleton('O2::Mgr::MemberManager')->getMemberByUsername( $obj->getParam('oldUsername') ),
    msg    => $obj->getParam('msg') || '',
  );
}
#--------------------------------------------------------------------------------------#
sub saveNewUsername {
  my ($obj) = @_;
  my $oldUsername = $obj->getParam('oldUsername');
  my $newUsername = $obj->getParam('newUsername');
  my $memberMgr = $context->getSingleton('O2::Mgr::MemberManager');
  my ($memberId) = $memberMgr->objectIdSearch(
    username   => $newUsername,
    metaStatus => { like => '%' },
  );
  my $msg = $obj->getLang()->getString('User.MemberManager.msgUsernameIsUnavailable');
  $cgi->redirect(
    setMethod => 'editUsername',
    setParams => "oldUsername=$oldUsername&msg=$msg",
  ) if $memberId;

  my $member = $memberMgr->getMemberByUsername($oldUsername);
  $member->setUsername($newUsername);
  $member->save();
  $cgi->redirect(
    setMethod => 'showMemberInfo',
    setParams => 'memberId=' . $member->getId(),
  );
}
#--------------------------------------------------------------------------------------#
sub addCanLoginAsMemberId {
  my ($obj) = @_;
  my %q = $obj->getParams();
  $context->getSingleton('O2::Mgr::MemberManager')->addCanLoginAsMember( $q{masterUserId}, $q{userId} );
  $obj->showMemberInfo();
}
#--------------------------------------------------------------------------------------#
sub deleteCanLoginAsMember {
  my ($obj) = @_;
  my %q = $obj->getParams();
  $context->getSingleton('O2::Mgr::MemberManager')->deleteCanLoginAs( $q{masterUserId}, $q{userId} );
  $obj->showMemberInfo();
}
#--------------------------------------------------------------------------------------#
sub setCanLoginAsAll {
  my ($obj) = @_;
  my %q = $obj->getParams();
  $context->getSingleton('O2::Mgr::MemberManager')->setCanLoginAsAll( $q{masterUserId} );
  $obj->showMemberInfo();
}
#--------------------------------------------------------------------------------------#
1;
