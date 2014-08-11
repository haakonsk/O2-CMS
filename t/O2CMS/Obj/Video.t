use strict;

use Test::More qw(no_plan);
use_ok 'O2::Context';
my $context = new O2::Context();
use_ok 'O2CMS::Mgr::VideoManager';

my $videoMgr = $context->getSingleton('O2CMS::Mgr::VideoManager');
my $video = $videoMgr->newObject();
$video->setMetaName('testscript O2CMS::Obj::Video/O2CMS::Mgr::VideoManager');
$video->setFileFormat('mpg');
$video->save();
ok($video->getId()>0, 'Object saved ok');
my $dbVideo = $videoMgr->getObjectById( $video->getId() );
ok(ref $dbVideo eq 'O2CMS::Obj::Video', 'Object retrieved from db ok');

$video->deletePermanently();
