package O2CMS::Search::ObjectIndexer;

use base 'O2CMS::Search::Base';

use constant DEBUG => 1;
use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  $params{indexName} ||= $config->get('o2.search.defaultObjectIndexName') || 'o2GenericIndex';
  my $obj = $pkg->SUPER::new(%params);
  
  my $documenter = $context->getSingleton('O2CMS::Search::Documenter', indexName => $obj->getIndexName() );
  $obj->setDocumenter($documenter);
  
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub setDocumenter {
  my ($obj, $documenter) = @_;
  $obj->{documenter} = $documenter;
}
#--------------------------------------------------------------------------------------------
sub getDocumenter {
  my ($obj) = @_;
  return $obj->{documenter};
}
#--------------------------------------------------------------------------------------------
sub removeObject {
  my ($obj, $object) = @_;
  $obj->getDocumenter()->removeDocument( id => $object->getId() );
}
#--------------------------------------------------------------------------------------------
# added by nilschd 20061130, sometimes I got the Id for object. But since the object is trashed I can't instance it as an O2 object (coz status eq 'trashed')
sub removeObjectById {
  my ($obj, $objectId) = @_;
  $obj->getDocumenter()->removeDocument( id => $objectId );
}
#--------------------------------------------------------------------------------------------
sub getFilter {
  my ($obj) = @_;
  if (!$obj->{filter}) {
    require SWISH::Filter;
    $obj->setFilter( SWISH::Filter->new() );
  }
  return $obj->{filter};
}
#--------------------------------------------------------------------------------------------
sub setFilter {
  my ($obj, $filter) = @_;
  $obj->{filter} = $filter;
}
#--------------------------------------------------------------------------------------------
sub errorWithFileFiltering {
  my ($obj, $file, $error) = @_;
  # Replace with console
  warning "**ERROR** Could not filter and add file (" . $file->getId() .  "): $error\n";
}
#--------------------------------------------------------------------------------------------
sub addOrUpdateObject {
  my ($obj, $object, %params) = @_;
  die "No object supplied" unless ref $object;
  
  my ($content, $extension);
  my $allowIndexing = $object->getPropertyValue('allowIndexing');
  if (defined $allowIndexing  &&  $allowIndexing ne 'yes'  &&  $obj->getIndexName() eq 'o2GenericIndex') {
    $obj->removeObject($object);
    debug "Ooops! Object is NOT ALLOWED to be indexed (please setPropertyValue('allowIndexing' => 'yes'))\n";
    return;
  }
  
  # If the object to be indexed is a file-object we need to convert it before we can go on
  if ($object->isa('O2::Obj::File')) {
    return if $object->getFileFormat() !~ m/^(pdf|doc|ppt)$/i; # XXX Move to config
    
    debug "Indexing file ", $object->getMetaName(), " (Id: ", $object->getId(),")\n";
    
    my $filteredDocument = $obj->getFilter()->convert( document => $object->getFilePath() );
    
    return $obj->errorWithFileFiltering( $object, 'No filtered document'      ) unless $filteredDocument;
    return $obj->errorWithFileFiltering( $object, 'Document was not filtered' ) unless $filteredDocument->was_filtered();
    
    $content = $filteredDocument->fetch_doc();
    return $obj->errorWithFileFiltering($object, 'No content in document') unless $content;
    
    $extension = lc $filteredDocument->swish_parser_type(); # Returns TXT*, XML*, HTML* or undefined
    $extension =~ s/\*//;
    
    return $obj->errorWithFileFiltering($object, 'No extension') unless $extension; # Need an extension, otherwise it won't work
  }
  elsif ($params{attributes}) {
    $content = $params{attributes};
    $content->{title} ||= $object->getMetaName();
  }
  else {
    $content = $object->getObjectPlds();
    $content->{title} ||= $object->getMetaName();
  }
  
  # XXX Must/should add: $content->{description}
  
  $obj->getDocumenter()->addOrUpdateDocument(
    id        => $object->getId(),
    content   => $content,
    extension => $extension,
  );
}
#--------------------------------------------------------------------------------------------
sub index {
  my ($obj, $indexName) = @_;
  $context->getSingleton( 'O2CMS::Search::Indexer', indexName => $indexName || $obj->getIndexName() )->createIndex();
}
#--------------------------------------------------------------------------------------------
1;
