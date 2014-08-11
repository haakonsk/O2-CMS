use strict;

use Test::More tests => 6;
use Test::Warn;

use O2::Script::Test::Common;

use O2::Context;
my $context = O2::Context->new();
my $dbh = $context->getDbh();

diag "Creating category";
my $cat = $context->getSingleton('O2CMS::Mgr::CategoryManager')->newObject();
$cat->setMetaName('Cat test');
$cat->setTitle('Cat test title');
$cat->save();

diag "Creating directory";
my $dir = $context->getSingleton('O2CMS::Mgr::DirectoryManager')->newObject();
$dir->setMetaName('Dir test');
$dir->setPath('/www/test');
$dir->save();
my $id = $dir->getId();

diag "Changing class to O2CMS::Obj::Category";
$dir = $context->getObjectById($id);
$dir->setMetaClassName('O2CMS::Obj::Category');
$dir->setTitle('Test title');
$dir->save();

diag "Testing";
my $catId = $dbh->fetch( "select objectId from O2CMS_OBJ_CATEGORY where objectId = ?", $id );
is($catId, $id, "Present in category");
my $dirId = $dbh->fetch( "select objectId from O2CMS_OBJ_DIRECTORY where objectId = ?", $id );
ok(!$dirId, "Not present in directory");

diag "Changing class back to O2CMS::Obj::Directory";
my $dir2 = $context->getObjectById($id);
$dir2->setMetaClassName('O2CMS::Obj::Directory');
$dir2->setPath('/www/test');
warning_like {
  $dir2->save();
} qr{idUpdate: no rows affected}, "'No rows affected' warning detected";

diag "Testing more";
my @values = $dbh->selectColumn("select value from O2_OBJ_OBJECT_VARCHAR where objectId = ?", $id);
ok(!@values, "No values");
$catId = $dbh->fetch( "select objectId from O2CMS_OBJ_CATEGORY where objectId = ?", $id );
ok(!$catId, "Not present in category");
$dirId = $dbh->fetch( "select objectId from O2CMS_OBJ_DIRECTORY where objectId = ?", $id );
is($dirId, $id, "Present in directory");

END {
  diag "Cleaning up";
  $dir->setMetaClassName('O2CMS::Obj::Directory');
  $dir->deletePermanently() if $dir;
  $cat->deletePermanently() if $cat;
}
