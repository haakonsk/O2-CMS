package O2CMS::Frontend::Gui::Survey::Poll;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi $session);

#-----------------------------------------------------------------------------
sub showResults {
  my ($obj, $message, $messageType) = @_;
  my $poll = $context->getObjectById( $obj->getParam('pollId') );
  if (!$poll || !$poll->isAllowedToSeeResults()) {
    $obj->display('notAllowedToSeeResults.html');
    return;
  }
  $obj->display(
    $obj->getObjectTemplatePath($poll),
    isShowResults => 1,
    message       => $message,
    messageType   => $messageType,
    alternatives  => [ $poll->getResults() ],
    object        => $poll,
  );
}
#-----------------------------------------------------------------------------
sub showResultsPopup {
  my ($obj) = @_;
  my $poll = $context->getObjectById( $obj->getParam('pollId') );
  $obj->displayBlankPage(
    $obj->getObjectTemplatePath($poll),
    isShowResults => 1,
    alternatives  => [ $poll->getResults() ],
    object        => $poll,
  );
}
#-----------------------------------------------------------------------------
sub saveVote {
  my ($obj) = @_;
  my $poll = $context->getObjectById( $obj->getParam('pollId') );
  if (!$poll->isAllowedToVote()) {
    $obj->showResults( $poll->getNotAllowedToVoteMessage(), 'error' );
    return;
  }
  require O2CMS::Mgr::Survey::Poll::VoteManager;
  my $voteMgr = O2CMS::Mgr::Survey::Poll::VoteManager->new();
  my $vote = $voteMgr->newObject();
  $vote->setMetaName(     'Poll vote'                  );
  $vote->setMetaParentId( $poll->getId()               );
  $vote->setAlternative(  $obj->getParam('pollAnswer') );
  $vote->setIpAddress(    $context->getClientIp()      );
  $vote->setUserId(       $session->get('userId')      ) if $session->get('userId');
  $vote->save();

  if ($poll->getRestrictAnswersBasedOn() eq 'cookie') {
    my %cookie = (
      name  => $poll->getCookieName(),
      value => 1,
    );
    $cookie{expires} = time + 60*$poll->getUserLockedDuration() if $poll->getUserLockedDuration() > 0;
    $cgi->setCookie(%cookie); # Set cookie to signal he has voted
  }

  $obj->showResults( $obj->{lang}->getString('Survey.Poll.msgVoteRegistered'), 'info' );
}
#-----------------------------------------------------------------------------
sub isAllowedToVote {
  my ($obj) = @_;
  my $poll = $context->getObjectById( $obj->getParam('pollId') );
  if (ref $poll ne 'O2CMS::Obj::Survey::Poll') {
    die 'Invalid pollId: ' . $obj->getParam('pollId') . '. This id actually refers to an object of type ' . ref($poll) . ' and metaname "' . $poll->getMetaName() . '"';
  }
  if (!$poll->isAllowedToVote()) {
    $obj->showResults( $poll->getNotAllowedToVoteMessage(), 'error' );
    return;
  }
  $obj->error();
}
#-----------------------------------------------------------------------------
# Returns a template selected for a slot containing this poll (if this poll is dropped on more than one slot and
# different templates are chosen for the slots, the result from this method is kind of random..)
sub getObjectTemplatePath {
  my ($obj, $poll) = @_;
  my $slotMgr = $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
  my @templateIds = $slotMgr->getObjectTemplateIdsByContentId( $poll->getId() );
  foreach my $templateId (@templateIds) {
    next unless $templateId;
    my $template = $context->getObjectById($templateId);
    return $template->getFullPath();
  }
  # If the poll hasn't been published anywhere, we still shouldn't die if an object template has been associated with polls:
  my $templateObjectMgr = $context->getSingleton('O2CMS::Mgr::Template::ObjectManager');
  my @templates = $templateObjectMgr->queryTemplates(class => ref $poll);
  foreach my $template (@templates) {
    return $template->getPath();
  }
  die "Didn't find object template for poll \"" . $poll->getMetaName() . '" (' . $poll->getId() . ')';
}
#-----------------------------------------------------------------------------
sub reloadPoll {
  my ($obj) = @_;
  my $poll = $context->getObjectById( $obj->getParam('pollId') );
  $obj->display(
    $obj->getObjectTemplatePath($poll),
    isShowResults => 0,                
    object        => $poll,
  );
}
#-----------------------------------------------------------------------------
1;
