use O2::Util::SetApacheEnv;

use O2 qw($context);

my $DEBUG = grep {/\--debug/} @ARGV;

my $indexer      = $context->getSingleton('O2CMS::Search::ObjectIndexer');
my $universalMgr = $context->getUniversalManager();

$indexer->setDebug($DEBUG);

foreach my $object ($universalMgr->getObjectsByClassNameAndStatus('O2CMS::Obj::Article' => 'approved')) {  
  $indexer->addOrUpdateObject($object);
  print "Added article '" . $object->getMetaName() . "' (" . $object->getId() . ")\n" if $DEBUG;
}

eval {
  require SWISH::Filter;
};
if ($@) {
  warn "Could not locate SWISH::Filter - please install in order to have files indexed properly\n";
}
else {
  foreach my $object ($universalMgr->getObjectsByClassNameAndStatus('O2::Obj::File' => 'active')) {  
    $indexer->addOrUpdateObject($object);
    print "Added file '" . $object->getMetaName() . "' (" . $object->getId() . ") => " . $object->getFilePath() . "\n" if $DEBUG;
  }
}

$indexer->index();
