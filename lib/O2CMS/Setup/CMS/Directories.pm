package O2CMS::Setup::CMS::Directories;

use strict;

use base 'O2::Setup::Directories';

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  
  my $setupConf = $obj->getSetupConf();
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  print "  Symlinking $setupConf->{o2CmsRoot} => $customerPath/o2-cms" if $obj->debug();
  symlink $setupConf->{o2CmsRoot}, "$customerPath/o2-cms" or die "Could not make symlink from $setupConf->{o2CmsRoot} to $customerPath/o2-cms $!";
  
  return 1;  
}
#---------------------------------------------------------------------
sub getDirectories {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  my @directories = (
    'o2/var/templates/frontend',
    'o2/var/templates/frontend/grids',
    'o2/var/templates/frontend/grids/text',
    'o2/var/templates/frontend/includes',
    'o2/var/templates/frontend/objects',
    'o2/var/templates/frontend/pages',
  );
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  @directories = map { "$customerPath/$_" } @directories;
  return @directories;
}
#---------------------------------------------------------------------
1;
