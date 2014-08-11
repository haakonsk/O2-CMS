package O2CMS::Setup::CMS::Configs;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);

#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;

  $obj->SUPER::install();
  $obj->createPluginsDotConf();

  return 1;
}
#---------------------------------------------------------------------
sub createPluginsDotConf {
  my ($obj) = @_;

  my $setupConf = $obj->getSetupConf();

  my $customerPath = join '/', $setupConf->{customersRoot}, $setupConf->{customer};

  my $content = <<"END";
[
  {
    name    => 'O2 Shop',
    root    => '$customerPath/o2-cms/plugins/shop',
    enabled => '0',
  },
  {
    name    => 'CMS',
    root    => '$customerPath/o2-cms',
    enabled => '1'
  }
];
END
  require O2::Util::Commandline;
  my $cmdline = O2::Util::Commandline->new();
  $cmdline->writeFileWithConfirm("$customerPath/o2/etc/conf/plugins.conf", $content);
  print "  $customerPath/o2/etc/conf/plugins.conf created\n" if $obj->verbose();
  
  $context->loadPlugins();
  $config->loadConfDirs();
}
#---------------------------------------------------------------------
1;
