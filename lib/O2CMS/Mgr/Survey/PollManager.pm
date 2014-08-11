package O2CMS::Mgr::Survey::PollManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $cgi $session);
use O2CMS::Obj::Survey::Poll;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Survey::Poll',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title                       => { type => 'varchar', multilingual => 1                       },
    question                    => { type => 'varchar', multilingual => 1                       },
    answerAlternatives          => { type => 'varchar', multilingual => 1, listType => 'array'  },
    allowMultipleAnswersPerUser => { type => 'bit'                                              },
    restrictAnswersBasedOn      => { type => 'varchar', validValues => ['cookie', 'user', 'ip'] },
    userLockedDuration          => { type => 'int'                                              }, # Number of minutes the user is unable to vote after submitting a vote
    endEpoch                    => { type => 'int'                                              }, # After this date no more votes can be submitted
    resultVisibleBeforeEndEpoch => { type => 'bit'                                              },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub getResults {
  my ($obj, $poll) = @_;
  my $voteMgr = $context->getSingleton('O2CMS::Mgr::Survey::Poll::VoteManager');
  return $voteMgr->getResultsFor($poll);
}
#-----------------------------------------------------------------------------
sub isAllowedToVote {
  my ($obj, $poll) = @_;
  return $obj->setNotAllowedToVoteMessage($poll, 'errorPastEndDate') if $poll->getEndEpoch() && time() > $poll->getEndEpoch();
  my $voteMgr = $context->getSingleton('O2CMS::Mgr::Survey::Poll::VoteManager');
  if ($poll->getAllowMultipleAnswersPerUser()) {
    $obj->setNotAllowedToVoteMessage($poll, '');
    return 1;
  }

  if ($poll->getRestrictAnswersBasedOn() eq 'cookie') {
    if (!$cgi->getCookie( $poll->getCookieName() )) {
      return $obj->setNotAllowedToVoteMessage($poll, '');
    }
    # Cookie exists, so he can't vote
    return $obj->setNotAllowedToVoteMessage($poll, 'errorCantVoteAgainYet');
  }

  if ($poll->getRestrictAnswersBasedOn() eq 'user') {
    my $userId = $session->get('userId');
    return $obj->setNotAllowedToVoteMessage($poll, 'errorNotLoggedIn') unless $userId;
    return $obj->setNotAllowedToVoteMessage($poll,                 '') unless $voteMgr->userIdHasVoted($userId, $poll->getId());
    return $obj->setNotAllowedToVoteMessage($poll, 'errorCantVoteAgain')   if $poll->getUserLockedDuration <= 0;
    if (time - $voteMgr->getLastVoteTimeOfUserId($userId, $poll->getId())   >   60*$poll->getUserLockedDuration()) {
      return $obj->setNotAllowedToVoteMessage($poll, ''); 
    }
    return $obj->setNotAllowedToVoteMessage($poll, 'errorCantVoteAgainYet');
  }

  if ($poll->getRestrictAnswersBasedOn() eq 'ip') {
    my $ip = $context->getClientIp();
    return $obj->setNotAllowedToVoteMessage($poll, 'errorNoIpAddress') unless $ip;
    return $obj->setNotAllowedToVoteMessage($poll,                 '') unless $voteMgr->ipHasVoted($ip, $poll->getId());
    return $obj->setNotAllowedToVoteMessage($poll, 'errorCantVoteAgain')   if $poll->getUserLockedDuration <= 0;
    if (time - $voteMgr->getLastVoteTimeOfIp($ip, $poll->getId())   >   60*$poll->getUserLockedDuration()) {
      return $obj->setNotAllowedToVoteMessage($poll, ''); 
    }
    return $obj->setNotAllowedToVoteMessage($poll, 'errorCantVoteAgainYet');
  }

  die "Shouldn't get here. Wrong value for \$poll->getRestrictAnswersBasedOn()..? Value is " . $poll->getRestrictAnswersBasedOn();
}
#-----------------------------------------------------------------------------
sub isAllowedToSeeResults {
  my ($obj, $poll) = @_;
  return !$poll->getEndEpoch() || $poll->getResultVisibleBeforeEndEpoch(); #  ||  time() > $poll->getEndEpoch();
}
#-----------------------------------------------------------------------------
sub getNotAllowedToVoteMessage {
  my ($obj, $poll) = @_;
  return $obj->{notAllowedToVoteMessage}->{$poll->getId()};
}
#-----------------------------------------------------------------------------
sub setNotAllowedToVoteMessage {
  my ($obj, $poll, $errorMessageLanguageKey) = @_;
  $obj->{notAllowedToVoteMessage}->{ $poll->getId() } = $context->getLang()->getString("Survey.Poll.$errorMessageLanguageKey");
  return $errorMessageLanguageKey ? 0 : 1;
}
#-----------------------------------------------------------------------------
sub deleteObjectPermanentlyById {
  my ($obj, $objectId) = @_;
  # Delete votes for this poll
  my @votes = $obj->getAllVotes( $context->getObjectById($objectId) );
  foreach my $vote (@votes) {
    $vote->deletePermanently();
  }
  $obj->SUPER::deleteObjectPermanentlyById($objectId);
}
#-----------------------------------------------------------------------------
sub getAllVotes {
  my ($obj, $object) = @_;
  return $object->getChildren();
}
#-----------------------------------------------------------------------------
1;
