use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';
my $context = O2::Context->new();
use_ok 'O2::Mgr::MemberManager';

my $username = 'testscript'.time;
my $email    = $username.'@redpill-linpro.com';
my $password = 'secret';

my $memberMgr = $context->getSingleton('O2::Mgr::MemberManager');
my $member = $memberMgr->newObject();
$member->setMetaName(    "$username O2::Obj::Member" );
$member->setUsername(    $username                   );
$member->setEmail(       $email                      );
$member->setPassword(    $password                   );
$member->setFirstName(   'firstname'                 );
$member->setMiddleName(  ''                          );
$member->setLastName(    'lastname'                  );
$member->setGender(      'male'                      );
$member->setPhone(       '98632441'                  );
$member->setCountryCode( 'no'                        );
$member->setKeywordIds(  1, 2, 3                     );
$member->setAttribute(   'myAttrib', 123             );
$member->setBirthDate(   '19500101'                  );
$member->setCellPhone();
$member->setAddress();
$member->setPostalCode();
$member->setPostalPlace();
$member->setMetaParentId();

$member->save();
ok(time - $member->getMetaChangeTime() <= 10, 'changeTime is now');
ok($member->getId() > 0, 'Member saved');


my $dbMember = $memberMgr->getObjectById( $member->getId() );
is( $dbMember->getId(), $member->getId(), 'Member retrieved from db'   );
ok( $dbMember->isa('O2::Obj::Object'),    'Member isa O2::Obj::Object' );
ok( $dbMember->isa('O2::Obj::Person'),    'Member isa O2::Obj::Person' );
ok( $dbMember->isa('O2::Obj::Member'),    'Member isa O2::Obj::Member' );

is( $member->getUsername(),   $dbMember->getUsername(),   'username column match'   );
is( $member->getEmail(),      $dbMember->getEmail(),      'email column match'      );
is( $member->getPassword(),   $dbMember->getPassword(),   'password column match'   );
is( $member->getFirstName(),  $dbMember->getFirstName(),  'firstname column match'  );
is( $member->getMiddleName(), $dbMember->getMiddleName(), 'middlename column match' );
is( $member->getLastName(),   $dbMember->getLastName(),   'lastname column match'   );
is( $member->getGender(),     $dbMember->getGender(),     'gender matches'          );
is( $member->getPhone(),      $dbMember->getPhone(),      'tlf matches'             );
is( $member->getCountry(),    $dbMember->getCountry(),    'country matches'         );

my @searchResults = $member->getManager()->objectSearch(
  username           => {
    eq => $member->getUsername(),
  },
  metaClassName      => $member->getMetaClassName(),
  metaChangeTime     => {
    like => $member->getMetaChangeTime(),
  },
  'keywordIds' => {
    in      => [1, 2],
    notLike => 4,
  },
  -either => {
    id          => { like => $member->getId()                    },
    countryCode => { in   => [ $member->getCountryCode(), 'se' ] },
    email       => 'abc',
  },
  'attributes{myAttrib}' => $member->getAttribute('myAttrib'),
);
is( $searchResults[0]->getId(), $member->getId(), 'Search returned correct member object' );

$member->deleteAttribute('myAttrib');
is( $member->getAttribute('myAttrib'), undef, 'myAttrib attribute deleted' );
$member->save();

$dbMember = $memberMgr->getObjectById( $member->getId() );
is( $dbMember->getAttribute('myAttrib'), undef, 'myAttrib attribute still deleted' );

END {
  $member->deletePermanently() if $member;
}
