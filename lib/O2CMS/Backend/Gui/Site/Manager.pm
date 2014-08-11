package O2CMS::Backend::Gui::Site::Manager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $config);

#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;

  my %q = $obj->getParams();

  my $site = $q{objectId}  ?  $context->getObjectById( $q{objectId} )  :  $obj->_getSiteMgr()->newObject();;
  $site->setMetaParentId( $q{parentId} ) if $q{parentId};
  $site->setMetaName(     $q{hostname} );

  foreach my $locale (@{ $config->get('o2.locales') }) {
    $site->setCurrentLocale($locale);
    $site->setTitle( $q{"$locale.title"} );
  }

  $site->setHostname(      $q{hostname}      );
  $site->setPortNumber(    $q{portNumber}    ) if $q{portNumber};
  $site->setDirectoryName( $q{directoryName} ) if $q{directoryName};
  $site->save();
  $obj->display(
    objectId => $site->getId(),
  );
}
#-----------------------------------------------------------------------------
sub _getSiteMgr {
  my ($obj) = @_;
  return $context->getSingleton('O2CMS::Mgr::SiteManager');
}
#-----------------------------------------------------------------------------

1;
