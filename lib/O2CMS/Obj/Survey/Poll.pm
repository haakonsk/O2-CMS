package O2CMS::Obj::Survey::Poll;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub getAnswerAlternativeByIndex {
  my ($obj, $i) = @_;
  my @alternatives = $obj->getAnswerAlternatives();
  return $alternatives[$i];
}
#-----------------------------------------------------------------------------
sub getNumberOfAnswerAlternatives {
  my ($obj) = @_;
  my @alternatives = $obj->getAnswerAlternatives();
  return scalar(@alternatives);
}
#-----------------------------------------------------------------------------
sub getResults {
  my ($obj) = @_;
  return $obj->getManager()->getResults($obj);
}
#-----------------------------------------------------------------------------
sub isAllowedToVote {
  my ($obj) = @_;
  return $obj->getManager()->isAllowedToVote($obj);
}
#-----------------------------------------------------------------------------
sub isAllowedToSeeResults {
  my ($obj) = @_;
  return $obj->getManager()->isAllowedToSeeResults($obj);
}
#-----------------------------------------------------------------------------
sub getNotAllowedToVoteMessage {
  my ($obj) = @_;
  return $obj->getManager()->getNotAllowedToVoteMessage($obj);
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub canMove {
  return 1;
}
#-----------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getCookieName {
  my ($obj) = @_;
  return 'o2Poll_' . $obj->getId();
}
#-----------------------------------------------------------------------------
sub getEndDateTime {
  my ($obj) = @_;
  return $context->getSingleton('O2::Mgr::DateTimeManager')->newObject( $obj->getEndEpoch() );
}
#-----------------------------------------------------------------------------
sub getChildren {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildren( $obj->getId(), $skip, $limit );
}
#-----------------------------------------------------------------------------
sub getChildIds {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::MetaTreeManager')->getChildIds($obj, $skip, $limit);
}
#-----------------------------------------------------------------------------
1;
