package O2CMS::Mgr::Survey::Poll::VoteManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($db);
use O2CMS::Obj::Survey::Poll::Vote;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Survey::Poll::Vote',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    ipAddress   => { type => 'varchar'         },
    alternative => { type => 'int'             },
    userId      => { type => 'O2::Obj::Person' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub userIdHasVoted {
  my ($obj, $userId, $pollId) = @_;
  my $lastVoteTime = $obj->getLastVoteTimeOfUserId($userId, $pollId);
  return 1 if $lastVoteTime;
  return 0;
}
#-----------------------------------------------------------------------------
sub ipHasVoted {
  my ($obj, $ip, $pollId) = @_;
  my $lastVoteTime = $obj->getLastVoteTimeOfIp($ip, $pollId);
  return 1 if $lastVoteTime;
  return 0;
}
#-----------------------------------------------------------------------------
sub getLastVoteTimeOfUserId {
  my ($obj, $userId, $pollId) = @_;
  my ($lastVoteTime) = $db->fetch("select max(changeTime) from O2CMS_OBJ_SURVEY_POLL_VOTE v, O2_OBJ_OBJECT o where v.objectId = o.objectId and parentId = ? and userId = ?", $pollId, $userId);
  return $lastVoteTime;
}
#-----------------------------------------------------------------------------
sub getLastVoteTimeOfIp {
  my ($obj, $ip, $pollId) = @_;
  my ($lastVoteTime) = $db->fetch("select max(changeTime) from O2CMS_OBJ_SURVEY_POLL_VOTE v, O2_OBJ_OBJECT o where v.objectId = o.objectId and parentId = ? and ipAddress = ?", $pollId, $ip);
  return $lastVoteTime;
}
#-----------------------------------------------------------------------------
sub getResultsFor {
  my ($obj, $poll) = @_;

  my $results = $db->sqlHashRef(
    "select alternative, count(*) as count from O2CMS_OBJ_SURVEY_POLL_VOTE v, O2_OBJ_OBJECT o where v.objectId = o.objectId and parentId = ? group by alternative", $poll->getId()
  );
  my $totalNumVotes        = 0;
  my $highestNumberOfVotes = 0;
  foreach my $i (keys %{$results}) {
    $totalNumVotes       += $results->{$i};
    $highestNumberOfVotes = $results->{$i} if $results->{$i} > $highestNumberOfVotes;
  }

  my @alternatives;
  my @answerAlternatives = $poll->getAnswerAlternatives();
  foreach my $alternativeIndex (0 .. scalar (@answerAlternatives)-1) {
    my ($count) = $db->fetch("select count(*) as count from O2CMS_OBJ_SURVEY_POLL_VOTE v, O2_OBJ_OBJECT o where v.objectId = o.objectId and parentId = ? and alternative = ?", $poll->getId(), $alternativeIndex);
    push @alternatives, {
      index          => $alternativeIndex,
      text           => $poll->getAnswerAlternativeByIndex($alternativeIndex),
      numVotes       => $count,
      percentOfTotal => $totalNumVotes         ?  100 * $count/$totalNumVotes         :  0,
      percentOfMax   => $highestNumberOfVotes  ?  100 * $count/$highestNumberOfVotes  :  0,
    };
  }
  return @alternatives;
}
#-----------------------------------------------------------------------------
1;
