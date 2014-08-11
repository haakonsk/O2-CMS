#!/usr/bin/perl
#
#
# Insert world, continents, subregions and countries
# standard/25.locales.pl must be run first (in fact - all standard/ scripts must be run before any optional/)

use strict;
use XML::XPath;
use O2::Context;

my $context = O2::Context->new();

my $xp = XML::XPath->new(filename => "$ENV{O2ROOT}/var/resources/cldr/common/supplemental/supplementalData.xml");
my %groups = ();
my $nodeset = $xp->find('/supplementalData/territoryContainment/group');
foreach my $node ($nodeset->get_nodelist) {
  $groups{$node->getAttribute('type')} = [split /\s+/, $node->getAttribute('contains')];
}

my $world = insert('O2CMS::Obj::Territory::World', '001', undef);
foreach my $continentId (@{$groups{'001'}}) {
  my $continent = insert('O2CMS::Obj::Territory::Continent', $continentId, $world);
  foreach my $subregionId (@{$groups{$continentId}}) {
    next if $subregionId eq 'QU'; # ignore EU
    my $subregion = insert('O2CMS::Obj::Territory::Subregion', $subregionId, $continent);
    foreach my $countryId (@{$groups{$subregionId}}) {
      my $country = insert('O2CMS::Obj::Territory::Country', $countryId, $subregion);
    }
  }
}


sub insert {
  my ($className, $code, $parent) = @_;
  
  my $territory = undef;
  my $manager = $context->getSingleton('O2::Mgr::UniversalManager')->getManagerByClassName($className);
  if( $parent ) {
    $territory = $parent->addOrUpdateChild(code=>$code, className=>$className, metaName=>$code);
  } else {
    ($territory) = $manager->queryTerritories(codePath=>$code);
    $territory ||= $manager->newObject();
    $territory->setCode($code);
    $territory->setCodePath($code);
  }
  print $territory->getId() ? 'Update' : 'Insert', ' ', $territory->getName(),"\n";
  $territory->setMetaName($territory->getName() || $code); # localized name
  $territory->save();
  return $territory;
}
