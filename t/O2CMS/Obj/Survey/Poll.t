use Test::More qw(no_plan);

use O2 qw($context $config);

my @locales = @{ $config->get('o2.locales') };
my $mgr = $context->getSingleton('O2CMS::Mgr::Survey::PollManager');

my $newObj = $mgr->newObject();
$newObj->setMetaName('Test-script for O2CMS::Obj::Survey::Poll/O2CMS::Mgr::Survey::PollManager');
$newObj->setResultVisibleBeforeEndEpoch(1);
$newObj->setEndEpoch(1);
$newObj->setAllowMultipleAnswersPerUser(1);
$newObj->setUserLockedDuration(1);
$newObj->setRestrictAnswersBasedOn('cookie');

foreach my $locale (@locales) {
  $newObj->setCurrentLocale($locale);
  $newObj->setQuestion('Test-varchar ($locale)');
  $newObj->setAnswerAlternatives('one ($locale)', 'two ($locale)');
  $newObj->setTitle('Test-varchar ($locale)');
}
$newObj->save();

ok($newObj->getId() > 0, 'Object saved ok');

my $dbObj = $context->getObjectById( $newObj->getId() );
ok($dbObj->getResultVisibleBeforeEndEpoch() eq $newObj->getResultVisibleBeforeEndEpoch(), 'resultVisibleBeforeEndEpoch retrieved ok.');
ok($dbObj->getEndEpoch() eq $newObj->getEndEpoch(), 'endEpoch retrieved ok.');
ok($dbObj->getAllowMultipleAnswersPerUser() eq $newObj->getAllowMultipleAnswersPerUser(), 'allowMultipleAnswersPerUser retrieved ok.');
ok($dbObj->getUserLockedDuration() eq $newObj->getUserLockedDuration(), 'userLockedDuration retrieved ok.');
ok($dbObj->getRestrictAnswersBasedOn() eq $newObj->getRestrictAnswersBasedOn(), 'restrictAnswersBasedOn retrieved ok.');
foreach my $locale (@locales) {
  $newObj->setCurrentLocale($locale);
  ok($dbObj->getQuestion() eq $newObj->getQuestion(), 'question retrieved ok.');
  ok(_refsAreEqual([$dbObj->getAnswerAlternatives()], [$newObj->getAnswerAlternatives()]), 'answerAlternatives retrieved ok.');
  ok($dbObj->getTitle() eq $newObj->getTitle(), 'title retrieved ok.');
}
$newObj->deletePermanently();

sub _refsAreEqual {
  my ($ref1, $ref2) = @_;
  return $ref1 == $ref2 unless ref($ref1);
  return 0 if ref($ref1) ne ref($ref2);
  if (ref $ref1 eq 'ARRAY') {
    return 0 if scalar( @{$ref1} ) != scalar( @{$ref2} );
    foreach my $i (0 .. scalar(@{$ref1})-1) {
      return 0 unless _refsAreEqual($ref1->[$i], $ref2->[$i]);
    }
  }
  elsif (ref $ref1 eq 'HASH') {
    return 0 if scalar(keys(%$ref1)) != scalar(keys(%$ref2));
    foreach my $key (keys %{$ref1}) {
      return 0 unless _refsAreEqual($ref1->{$key}, $ref2->{$key});
    }
  }
  return 1;
}
