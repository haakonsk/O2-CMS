package O2CMS::Obj::Category;

use strict;

use base 'O2::Obj::Container';

use O2::Mgr::MetaTreeManager;

#-------------------------------------------------------------------------------
sub canRemoveObject {
  my ($obj, $object) = @_;
  return 1; # can remove anything
}
#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return 1; # can add anything
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 1; # can move to anywhere
}
#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
# In the URL, ignore Category objects that are not WebCategory objects
sub getUrl {
  my ($obj) = @_;
  my $parent = $obj->getParent() or die "Didn't find parent";
  return $parent->getUrl();
}
#-------------------------------------------------------------------------------
1;
