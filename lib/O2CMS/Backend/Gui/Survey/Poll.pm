package O2CMS::Backend::Gui::Survey::Poll;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub newObject {
  my ($obj) = @_;
  my $poll = $context->getSingleton('O2CMS::Mgr::Survey::PollManager')->newObject();
  $poll->setMetaParentId( $obj->getParam('parentId') );
  $obj->edit($poll, 1);
}
#-----------------------------------------------------------------------------
sub edit {
  my ($obj, $poll, $isNewObject) = @_;
  $poll ||= $obj->getObjectByParam('objectId');
  $obj->display(
    'edit.html',
    object      => $poll,
    isNewObject => $isNewObject,
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  my $q = $cgi->getStructure('object');
  my $poll;
  if ($q->{id}) {
    $poll = $context->getObjectById( $q->{id} );
  }
  else {
    my $pollMgr = $context->getSingleton('O2CMS::Mgr::Survey::PollManager');
    $poll = $pollMgr->newObject();
    $poll->setMetaParentId( $q->{parentId} );
  }

  my $endDate = $q->{endDate};
  if ($endDate) {
    my ($hours, $minutes) = $q->{endTime} =~ m{ (\d\d) : (\d\d) }xms;
    $endDate->setHours(   $hours   );
    $endDate->setMinutes( $minutes );
  }
  
  $poll->setMetaName(                    $q->{title}                             ) unless $poll->getMetaName();
  $poll->setAllowMultipleAnswersPerUser( $q->{allowMultipleAnswersPerUser} || 0  );
  $poll->setRestrictAnswersBasedOn(      $q->{restrictAnswersBasedOn}            ) if !$q->{allowMultipleAnswersPerUser};
  $poll->setUserLockedDuration(          $q->{userLockedDuration}                ) if !$q->{allowMultipleAnswersPerUser};
  $poll->setEndEpoch(                    $endDate ? $endDate->getEpoch() : undef );
  $poll->setResultVisibleBeforeEndEpoch( $q->{resultVisibleBeforeEndEpoch} || 0  ) if $endDate;
  foreach my $locale ($obj->_getLocales($q)) {
    $poll->setCurrentLocale($locale);
    $poll->setTitle(                 $q->{$locale}->{title}                 );
    $poll->setQuestion(              $q->{$locale}->{question}              );
    $poll->setAnswerAlternatives( @{ $q->{$locale}->{answerAlternatives} }  );
  }
  $poll->save();
  return {
    objectId => $poll->getId(),
  };
}
#-----------------------------------------------------------------------------
sub _getLocales {
  my ($obj, $q) = @_;
  my @locales;
  foreach my $locale (keys %{$q}) {
    next if $locale !~ m{ \w\w_\w\w }xms || ref $q->{$locale} ne 'HASH';
    push @locales, $locale;
  }
  return @locales;
}
#-----------------------------------------------------------------------------

1;
