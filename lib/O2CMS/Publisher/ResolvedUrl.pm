package O2CMS::Publisher::ResolvedUrl;

# Description: Contains info about a resolved url

use strict;

use O2 qw($context);

#--------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#--------------------------------------------------------------
sub setUrl {
  my ($obj, $url) = @_;
  $obj->{url} = $url;
}
#--------------------------------------------------------------
sub getUrl {
  my ($obj) = @_;
  return $obj->{url};
}
#--------------------------------------------------------------
sub setSiteId {
  my ($obj, $siteId) = @_;
  $obj->{siteId} = $siteId;
}
#--------------------------------------------------------------
sub getSiteId {
  my ($obj) = @_;
  return $obj->{siteId};
}
#--------------------------------------------------------------
sub setCategoryPathIds {
  my ($obj, @categoryPathIds) = @_;
  $obj->{categoryPathIds} = \@categoryPathIds;
}
#--------------------------------------------------------------
sub getCategoryPathIds {
  my ($obj) = @_;
  return @{ $obj->{categoryPathIds} };
}
#--------------------------------------------------------------
sub getLastCategoryId {
  my ($obj) = @_;
  my @categoryPathIds = $obj->getCategoryPathIds();
  return $categoryPathIds[-1] || $obj->getSiteId();
}
#--------------------------------------------------------------
sub setContentObjectId {
  my ($obj, $contentObjectId) = @_;
  $obj->{contentObjectId} = $contentObjectId;
}
#--------------------------------------------------------------
sub getContentObjectId {
  my ($obj) = @_;
  return $obj->{contentObjectId};
}
#--------------------------------------------------------------
# returns object path (starting with Site, not Installation)
sub getObjectPath {
  my ($obj) = @_;
  return @{ $obj->{objectPath} } if $obj->{objectPath};
  
  my @objectPath = $context->getObjectsByIds( $obj->getSiteId(), $obj->getCategoryPathIds(), $obj->getContentObjectId() );
  $obj->{objectPath} = \@objectPath;
  return @objectPath;
}
#--------------------------------------------------------------
sub asString {
  my ($obj) = @_;
  return "$obj->{url} - http://$obj->{siteId}/" . join ('/', @{ $obj->{categoryPathIds} }) . "/$obj->{contentObjectId}.o2";
}
#--------------------------------------------------------------
1;
