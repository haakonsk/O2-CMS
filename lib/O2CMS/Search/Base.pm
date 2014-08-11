package O2CMS::Search::Base;

use strict;

use O2 qw($context $config);

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  die "No indexName supplied" if !$params{indexName} && !$params{indexNames};

  my $obj = bless { configs => [] }, $package;

  $obj->setDebug(         $params{debug}        ) if $params{debug};
  $obj->setIndexName(     $params{indexName}    ) if $params{indexName};
  $obj->setIndexNames( @{ $params{indexNames} } ) if $params{indexNames};

  return $obj;
}
#---------------------------------------------------------------------------------------------------------------
sub getDocumentsPath {
  my ($obj) = @_;
  return $obj->{documentsPath} || $config->get('o2.search.documentsPath');
}
#---------------------------------------------------------------------------------------------------------------
sub setDocumentsPath {
  my ($obj, $documentsPath) = @_;
  $obj->{documentsPath} = $documentsPath;
}
#---------------------------------------------------------------------------------------------------------------
sub setIndexName {
  my ($obj, $indexName) = @_;
  $obj->{indexName} = $indexName;
}
#---------------------------------------------------------------------------------------------------------------
sub getIndexName {
  my ($obj) = @_;
  return $obj->{indexName};
}
#---------------------------------------------------------------------------------------------------------------
sub setIndexNames {
  my ($obj, @indexNames) = @_;
  $obj->{indexNames} = \@indexNames;
}
#---------------------------------------------------------------------------------------------------------------
sub getIndexNames {
  my ($obj) = @_;
  return @{ $obj->{indexNames} };
}
#---------------------------------------------------------------------------------------------------------------
sub setDebug {
  my ($obj, $debug) = @_;
  $obj->{debug} = $debug;
}
#---------------------------------------------------------------------------------------------------------------
sub getDebug {
  my ($obj) = @_;
  return $obj->{debug};
}
#---------------------------------------------------------------------------------------------------------------
sub getConfigsPath {
  my ($obj) = @_;
  return $obj->{configsPath} || $config->get('o2.search.configsPath');
}
#---------------------------------------------------------------------------------------------------------------
sub setConfigsPath {
  my ($obj, $configsPath) = @_;
  $obj->{configsPath} = $configsPath;
}
#---------------------------------------------------------------------------------------------------------------
sub getIndexesPath {
  my ($obj) = @_;
  return $obj->{indexesPath} || $config->get('o2.search.indexesPath');
}
#---------------------------------------------------------------------------------------------------------------
sub setIndexesPath {
  my ($obj, $indexesPath) = @_;
  $obj->{indexesPath} = $indexesPath;
}
#---------------------------------------------------------------------------------------------------------------
1;
