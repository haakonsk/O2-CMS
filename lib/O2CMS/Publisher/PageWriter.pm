package O2CMS::Publisher::PageWriter;

use strict;

use O2 qw($context $config);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#-------------------------------------------------------------------------------
sub writeFrontpageScript {
  my ($obj, %params) = @_;
  
  my $fileMgr = $context->getSingleton('O2::File');
  
  # generate script
  my $category = $params{category};
  return if !$category || !$category->isa('O2CMS::Obj::WebCategory'); # do not write index script to non webfolders
  
  # make sure we only overwrite publisher scripts
  my $path = $category->getDirectoryPath() . '/' . $config->get('publisher.directoryIndexScriptName');
  if (-f $path) {
    my $oldScript = $fileMgr->getFile($path);
    my $signature = $config->get('publisher.autoGeneratedSignature');
    if ($oldScript !~ m/$signature/) {
      $obj->_debug("Old script does not contain signature '$signature' $oldScript");
      return;
    }
  }
  
  # generate script
  my $url = $category->getUrl();
  my $script = '#!' . $config->get('publisher.perlPath')."\n";
  $script   .= "# " . $config->get('publisher.autoGeneratedSignature') . "\n\n";
  $script   .= "use O2::Cgi;\n";
  $script   .= "use O2::Dispatch;\n\n";
  $script   .= 'my $url = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}";' . "\n";
  $script   .= '$url =~ s{ index[.]cgi \z }{}xms;' . "\n\n";
  $script   .= "my \$cgi = O2::Cgi->new();\n";
  $script   .= "my \$dispatch = O2::Dispatch->new();\n";
  $script   .= "\$dispatch->dispatch(isPublisherRequest=>1, url=>\$url, cgi=>\$cgi);\n\n";
  $obj->_debug("Script: $script");
  
  # write script
  $obj->_debug("Writing script to '$path'");
  $fileMgr->writeFile($path, $script);
  chmod oct (775), $path;
  return 1;
}
#-------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg) = @_;
#  print "<font color=blue>$msg</font><br>\n";
}
#-------------------------------------------------------------------------------
1;