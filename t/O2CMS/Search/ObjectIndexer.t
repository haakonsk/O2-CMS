use strict;

use Test::More qw(no_plan);

use_ok('O2::Context');
my $context = O2::Context->new();

use_ok('O2CMS::Search::ObjectIndexer');
my $objIndexer = O2CMS::Search::ObjectIndexer->new( context => $context );

my $user = $context->getSingleton('O2CMS::Mgr::AdminUserManager')->newObject();
$user->setId(         999     );
$user->setFirstName( 'John'   );
$user->setLastName(  'Doe'    );
$user->setUsername(  'johnny' );

isa_ok($user, 'O2CMS::Obj::AdminUser');

$objIndexer->addOrUpdateObject($user);

$objIndexer->index();
