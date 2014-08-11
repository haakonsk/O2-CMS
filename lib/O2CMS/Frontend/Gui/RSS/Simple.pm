package O2CMS::Frontend::Gui::RSS::Simple;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi $config);

#------------------------------------------------------------------
sub setDisplayContentType {
  my ($obj) = @_;
  $cgi->setContentType('application/rss+xml');
}
#------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  
  my $site      = $context->getSingleton( 'O2CMS::Mgr::SiteManager'      )->getSiteByHostname( $context->getEnv('SERVER_NAME') );
  my $frontpage = $context->getSingleton( 'O2CMS::Mgr::FrontpageManager' )->getFrontpageByCategoryId( $obj->getParam('cid') || $site->getId() );
  
  my @slotObjects;
  foreach my $rssSlotId (@{ $config->get('o2.rss.slotIds') }) {
    my $object = $frontpage->getSlotContentById($rssSlotId);
    push @slotObjects, $object if ref $object && $object->isa('O2CMS::Obj::Article'); # XXX May add filtering by regex from config?
  }
  
  $obj->display(
    'template.xml',
    site      => $site,
    frontpage => $frontpage,
    objects   => \@slotObjects,
    buildTime => time-10, # Some validators clock seems to be running a little slow
  );
}
#------------------------------------------------------------------
1;
