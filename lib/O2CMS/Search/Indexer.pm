package O2CMS::Search::Indexer;

use strict;

use base 'O2CMS::Search::Base';

use constant DEBUG => 1;
use O2 qw($context $config);

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = $package->SUPER::new(%params);
  
  my $howToHandleMetaTags = $config->get('o2.search.howToHandleUndefinedMetaTags') || 'auto';
  
  $obj->setConfigDirectives(
    "UndefinedMetaTags $howToHandleMetaTags",
    'TranslateCharacters :ascii7:',
    'ParserWarnLevel 1',
    'IndexOnly .xml .htm .html .pdf .doc .xls .odt .plds',
  ); # Default add metaDatas + translate זרו etc.
  
  return $obj;
}
#---------------------------------------------------------------------------------------------------------------
sub setConfigDirectives { # Method for directly setting ALL configuration-values
  my ($obj, @configs) = @_;
  my @localConfigs = @configs; # Make sure we copy them
  $obj->{configs}  = \@localConfigs;
}
#---------------------------------------------------------------------------------------------------------------
sub addConfigDirective {
  my ($obj, $configDirective) = @_;
  push @{ $obj->{configs} }, $configDirective;
}
#---------------------------------------------------------------------------------------------------------------
sub getConfigDirectives { # Method for getting ALL configuration-values
  my ($obj) = @_;
  return @{ $obj->{configs} };
}
#---------------------------------------------------------------------------------------------------------------
sub createIndex { # Creates the index
  my ($obj) = @_;
  my $index = $obj->getIndexName();
  
  die "Illegal indexName '$index'" if $index !~ m/^[\w\d\-\_]+$/;
  
  my %params = (
    -i => $obj->getDocumentsPath() . "/$index",
    -c => $obj->getConfigsPath()   . "/$index.conf",
    -f => $obj->getIndexesPath()   . "/$index.idx",
    -v => 3,
    # debian 3.1 only has swish-e 2.4.3, can't use -W on samba
    #-W => 0, # ignore libxml2 warnings (swish-e 2.4.4 changed default setting from 0 to 2)
  );
  
  die "No permissions to write index '$params{-f}'"                                    unless -w $obj->getIndexesPath();
  die "No permissions to write configuration '$params{-c}'"                            unless -w $obj->getConfigsPath();
  die "Documents path '$params{-i}' does not exist/is not readable (nothing to index)" unless -r $params{-i};
  
  my $hostname = `hostname`;
  chomp $hostname;
  
  open CONF, ">".$params{-c} or die "Could not open config '$params{-c}' for writing";
  foreach my $configLine ($obj->getConfigDirectives()) {
    print CONF $configLine . "\n";
  }
  close (CONF);
  
  my $cmd    = $config->get('o2.search.swishBin');
  my $params = join ' ', map { "$_ $params{$_}" } keys %params;
  
  debug "Running: $cmd $params";
  local *INDEXER;
  open INDEXER, "$cmd $params|" or die "Could not open indexer ($cmd $params): $!";
  while (<INDEXER>) {
    debug "INDEXER SAYS: $_";
  }
  close INDEXER;
}
#---------------------------------------------------------------------------------------------------------------
sub removeIndex {
  my ($obj) = @_;
  
  my $indexName = $obj->getIndexName();
  die "Illegal indexName '$indexName'" if $indexName !~ /^[\w\d\-\_]+$/;
  
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->rmFile( $obj->getDocumentsPath() . "/$indexName", '-rf'   );
  $fileMgr->rmFile( $obj->getConfigsPath()   . "/$indexName.conf"     );
  $fileMgr->rmFile( $obj->getIndexesPath()   . "/$indexName.idx"      );
  $fileMgr->rmFile( $obj->getIndexesPath()   . "/$indexName.idx.prop" );
}
#---------------------------------------------------------------------------------------------------------------
1;
