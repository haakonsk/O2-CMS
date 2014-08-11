package O2CMS::Obj::Territory;

use strict;

use base 'O2::Obj::Container';

use O2 qw($context);

#-------------------------------------------------------------------------------
# returns localized name (if available)
sub getName {
  my ($obj) = @_;
  return $obj->getMetaName();
}
#-------------------------------------------------------------------------------
# returns code path for a child of this territory
sub getChildCodePathByCode {
  my ($obj, $code) = @_;
  die 'Missing code parameter' unless $code;
  return $obj->getCodePath() . "::$code";
}
#-------------------------------------------------------------------------------
# returns how many parents this territory has
sub getTreeLevel {
  my ($obj) = @_;
  return (scalar split '::', $obj->getCodePath())-1;
}
#-------------------------------------------------------------------------------
# returns object along with all parent territories. Ordered by tree level (top-territory, sub-territory, ... , $obj)
sub getPath {
  my ($obj) = @_;

  my @path = ($obj);
  my $node = $obj;
  while( @path <= $obj->getTreeLevel() ) {
    $node = $node->getParent();
    push @path, $node;
  }
  return reverse @path;
}
#-------------------------------------------------------------------------------
# returns short name describing territory type. I.e. "country" or "postalPlace"
sub getType {
  my ($obj) = @_;
  my ($type) = (ref $obj) =~ /(\w+)$/;
  return lcfirst $type;
}
#-------------------------------------------------------------------------------
sub getChildByCodeAndClassName {
  my ($obj, $code, $className) = @_;
  my $codePath = $obj->getChildCodePathByCode($code);
  my ($territory) = $obj->getManager()->queryTerritories(
    codePath   => $codePath,
    classNames => [$className],
  );
  return $territory;
}
#-------------------------------------------------------------------------------
# Init a child object and return it.
# You have to call save() on the object yourself.
sub addOrUpdateChild {
  my ($obj, %args) = @_;
  die 'Missing code parameter'      unless $args{code};
  die 'Missing className parameter' unless $args{className};
  
  my $territory = $obj->getChildByCodeAndClassName( $args{code}, $args{className} );
  $territory  ||= $context->getUniversalManager()->newObjectByClassName( $args{className} );

  $territory->setMetaName(     $args{metaName}                             );
  $territory->setMetaParentId( $obj->getId()                               );
  $territory->setCode(         $args{code}                                 );
  $territory->setCodePath(     $obj->getChildCodePathByCode( $args{code} ) );
  return $territory;
}
#-------------------------------------------------------------------------------
sub queryChildren {
  my ($obj, %args) = @_;
  $args{codePath} = $obj->getCodePath() . '::%';
  return $obj->getManager()->queryTerritories(%args);
}
#-------------------------------------------------------------------------------
# only way I could find to avoid revisions
sub isSerializable {
  return 0;
}
#-------------------------------------------------------------------------------
# return string representation of object and its children (for debugging)
sub dumpTree {
  my ($obj) = @_;
  return $obj->_dumpTree($obj, '');
}
#-------------------------------------------------------------------------------
sub _dumpTree {
  my ($obj, $node, $indent) = @_;
  my $result = $indent.' - '.$node->getName()."\n";
  foreach my $child ($node->getChildren()) {
    $result .= $obj->_dumpTree($child, "$indent  ");
  }
  return $result;
}
#-------------------------------------------------------------------------------
1;
