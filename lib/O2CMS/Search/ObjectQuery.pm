package O2CMS::Search::ObjectQuery;

use strict;

use base 'O2CMS::Search::Query';

use O2 qw($config);

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  if (!$params{indexName} && !$params{indexNames}) {
    $params{indexName} = $config->get('o2.search.defaultObjectIndexName') || 'o2GenericIndex';
  }
  my $obj = $package->SUPER::new(%params);
  return $obj;
}
#---------------------------------------------------------------------------------------------------------------
sub _getResultsClassName {
  return 'O2CMS::Search::ObjectResults';
}
#---------------------------------------------------------------------------------------------------------------
package O2CMS::Search::ObjectResults; # Inherited class

use base 'O2CMS::Search::Results';

use O2 qw($context);

#---------------------------------------------------------------------------------------------------------------
sub getNextObjectId {
  my ($obj) = @_;
  my $result = $obj->getNextResult();
  return unless $result;
  return $result->getId();
}
#---------------------------------------------------------------------------------------------------------------
sub getNextObject {
  my ($obj) = @_;
  while (my $objectId = $obj->getNextObjectId()) {
    my $object = $context->getObjectById($objectId);
    return $object if $object && $object->getPropertyValue('allowIndexing') eq 'yes';
  }
  return;
}
#---------------------------------------------------------------------------------------------------------------
sub getObjectIds {
  my ($obj) = @_;
  my @objectIds;
  foreach my $result ( $obj->getAllResults() ) {
    push @objectIds, $result->getId();
  }
  return @objectIds;
}
#---------------------------------------------------------------------------------------------------------------
sub getObjects {
  my ($obj) = @_;
  my @objects;
  foreach my $objectId ( $obj->getObjectIds() ) {
    my $object = $context->getObjectById($objectId) or next;
    next if $object->getPropertyValue('allowIndexing') ne 'yes';
    push @objects, $object if ref $object;
  }
  return @objects;
}
#---------------------------------------------------------------------------------------------------------------
1;
