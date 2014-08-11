package O2CMS::Mgr::SiteManager;

use strict;
use base 'O2CMS::Mgr::WebCategoryManager';

use O2 qw($context $config);
use O2CMS::Obj::Site;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Site',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    hostname   => { type => 'varchar', length => 128, notNull => 1 },
    portNumber => { type => 'int'                                  },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getSiteByHostname {
  my ($obj, $hostname) = @_;
  my @sites = $obj->objectSearch(
    hostname => $hostname,
  );
  return @sites ? $sites[0] : undef;
}
#-------------------------------------------------------------------------------
sub getSites {
  my ($obj) = @_;
  return $obj->objectSearch();
}
#-------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  my $isUpdate = $object->getId() > 0;
  $obj->SUPER::save($object);
  if (!$isUpdate && $context->getEnv('OS') ne 'Windows_NT' && $config->get('o2.apache.autoGenerateConfig') ne '0') {
    $obj->setupApache($object);
  }
}
#-------------------------------------------------------------------------------
sub setupApache {
  my ($obj, $object) = @_;
  $context->getSingleton('O2CMS::Setup::CMS::Apache')->createApacheConfig(
    hostname => $object->getHostname(),
    port     => $object->getPortNumber(),
    silent   => 1,
  );
}
#-------------------------------------------------------------------------------
1;
