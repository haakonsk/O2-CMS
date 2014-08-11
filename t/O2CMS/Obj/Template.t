use strict;

use Test::More qw(no_plan);

use O2 qw($context $config);

my $template = $context->getSingleton('O2CMS::Mgr::TemplateManager')->newObject();
$template->setMetaName( 'Object template'                             );
$template->setPath(     $config->get('setup.tmpDir') . '/object.html' );
$template->save();

my $dbObj = $context->getObjectById( $template->getId() );
is( $template->getMetaName(), $dbObj->getMetaName(), 'metaName ok' );
is( $template->getPath(),     $dbObj->getPath(),     'path ok'     );

END {
  $template->deletePermanently() if $template;
}
