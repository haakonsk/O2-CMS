package O2CMS::Publisher::PageCache::ObjectCacheHandler;

# Allow objects that want to reset the cached version of themselves to reset cached frontpages that they are published "on".
# Allowing object changes to be visible instantly on the web.

use strict;

use O2 qw($context $db);

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#-------------------------------------------------------------------------------
sub delCachedFrontpagesWithThisObject {
  my ($obj, $object) = @_;
  my @frontpageIds = $obj->getIdsOfFrontpagesContainingObjects( $object->getId() );
  return 1 unless @frontpageIds;
  
  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  foreach my $id (@frontpageIds) {
    $pageCache->delCacheById($id);
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub regenerateCachedFrontpagesWithThisObject {
  my ($obj, $object) = @_;
  my @frontpageIds = $obj->getIdsOfFrontpagesContainingObjects( $object->getId() );
  return 1 unless @frontpageIds;
  
  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  foreach my $id (@frontpageIds) {
    $pageCache->regenerateCacheById($id);
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub isCachedWithinAFrontpage {
  my ($obj, $object) = @_;
  my @frontpageIds = $obj->getIdsOfFrontpagesContainingObjects( $object->getId() );
  my $pageCache = $context->getSingleton('O2CMS::Publisher::PageCache');
  foreach my $id (@frontpageIds) {
    return 1 if $pageCache->isCachedById($id);
  }
  return 0;
}
#-------------------------------------------------------------------------------
sub getIdsOfFrontpagesContainingObjects {
  my ($obj, @objectIds) = @_;
  return $db->selectColumn("select distinct(s.objectId) from O2CMS_OBJ_TEMPLATE_SLOT s, O2_OBJ_OBJECT o where s.contentId in (??) and o.objectId = s.objectId and o.className like 'O2CMS::Obj::Frontpage'", \@objectIds);
}
#-------------------------------------------------------------------------------
1;
