package O2CMS::Search::Documenter;

use strict;

use base 'O2CMS::Search::Base';

use O2 qw($context);

#---------------------------------------------------------------------------------------------------------------
sub removeDocument {
  my ($obj, %params) = @_;
  die "No ID (id) supplied" unless $params{id};
  my $filePath = $obj->_getFilePathById( $params{id}, 'plds' );
  
  unlink $filePath  if -e $filePath;
  $filePath = $obj->_getFilePathById( $params{id}, 'xml' );
  unlink $filePath if -e $filePath;
}
#---------------------------------------------------------------------------------------------------------------
sub removeAllDocuments {
  my ($obj) = @_;
  my $rootDir = $obj->getDocumentsPath().'/'.$obj->getIndexName();
  return unless -w $rootDir;
  $context->getSingleton('O2::File')->rmFile($rootDir, '-rf');
}
#---------------------------------------------------------------------------------------------------------------
sub addOrUpdateDocument {
  my ($obj, %params) = @_;

  print "About to add or update document\n" if $obj->getDebug();
  
  my $fileMgr = $context->getSingleton('O2::File');
  
  die "No ID (id) supplied" unless $params{id};
  die "No content supplied" unless $params{content};

  if ($params{extension}) {
    my $filePath = $obj->_getFilePathById( $params{id}, $params{extension} );
    print "Writing ", uc($params{extension})," to '$filePath'\n" if $obj->getDebug();
    $fileMgr->writeFile($filePath, $params{content});
    return;
  }
  else {
    require O2::Util::XMLGenerator;
    my $xmlGenerator = O2::Util::XMLGenerator->new();
    my $xml = $xmlGenerator->toXml( document => $params{content} );
    
    my $xmlFilePath = $obj->_getFilePathById( $params{id}, 'xml' );

    require Encode;
    $xml = Encode::encode('iso-8859-1', $xml);
    
    print "Writing XML to '$xmlFilePath'\n" if $obj->getDebug();
    $fileMgr->writeFile($xmlFilePath, \$xml);
    
    my $pldsFilePath = $obj->_getFilePathById( $params{id}, 'plds' );
    print "Writing PLDS to '$pldsFilePath'\n" if $obj->getDebug();
    require O2::Data;
    my $data = O2::Data->new();
    my $plds = Encode::encode('iso-8859-1', $data->dump( $params{content} ));
    
    $plds =~ s/\\x{(\w\w)}/chr hex $1/eg; # XXX Why do we have characters like these?? Is it O2::Data?? Data::Dumper?

    $fileMgr->writeFile( $pldsFilePath, $plds );
  }
}
#---------------------------------------------------------------------------------------------------------------
sub _getFilePathById {
  my ($obj, $id, $extension) = @_;

  my $charsPerLevel;
  if ($id !~ m/^\d+$/) {
    $id =~ s/([^a-zA-Z0-9\-])/"_".uc(sprintf("%lx", ord($1)))/eg; # Make all illegal characters hex-encoded (eg. '/' becomes '_2F' ('_' becomes '_5F'))
    $charsPerLevel = 4;
  }

  my $filePath = $context->getSingleton('O2::File')->distributePath(
    id            => $id,
    rootDir       => $obj->getDocumentsPath().'/'.$obj->getIndexName(),
    fileName      => $id.'.'.$extension,
    charsPerLevel => $charsPerLevel,
    mkDirs        => 1,
  );
  
  return $filePath;
}
#---------------------------------------------------------------------------------------------------------------
1;
