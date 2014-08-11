package O2CMS::Backend::Gui::System::PropertyEditor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $session);
use Data::Dumper;

#--------------------------------------------------------------------------------
sub editDefinition {
  my ($obj) = @_;

  my $propertyDefinitionMgr = $context->getSingleton('O2::Mgr::PropertyDefinitionManager');
  my $definition = $propertyDefinitionMgr->getPropertyDefinitionByName( $obj->getParam('propertyName') ) || $propertyDefinitionMgr->newObject();
  if ( !$definition->getId() ) {
    $definition->setMetaName(     $obj->getParam('propertyName') );
    $definition->setPropertyName( $obj->getParam('propertyName') );
  }

  my @existingProperties = $obj->_listPropertyUsage( $definition->getPropertyName() );
  $obj->display(
    'editDefinition.html', 
    object             => $definition,
    existingProperties => \@existingProperties,
    returnToObjectId   => $obj->getParam('returnToObjectId'),
  );
}
#--------------------------------------------------------------------------------
sub _getDefinition {
  my ($obj) = @_;
  my $propertyDefinitionMgr = $context->getSingleton('O2::Mgr::PropertyDefinitionManager');

  my $definition = $propertyDefinitionMgr->getPropertyDefinitionByName( $obj->getParam('propertyName') );
  if (!$definition) {
    $definition = $propertyDefinitionMgr->newObject();
    $definition->setMetaName(     $obj->getParam('propertyName') );
    $definition->setMetaParentId( undef                          ); # undef means global, or definition may be available only for objects below parentId
  }
  return $definition;
}
#--------------------------------------------------------------------------------
sub saveDefinition {
  my ($obj) = @_;

  my $struct = $cgi->getStructure('object');

  my $propertyDefinitionMgr = $context->getSingleton('O2::Mgr::PropertyDefinitionManager');
  my $definition = $propertyDefinitionMgr->getPropertyDefinitionByName( $struct->{propertyName} ) || $propertyDefinitionMgr->newObject();

  $definition->setMetaName(         $struct->{propertyName}          ) unless $definition->getMetaName(); # do not overwrite existing name
  $definition->setPropertyName(     $struct->{propertyName}          );
  $definition->setMetaParentId(     $struct->{metaParentId} || undef );
  $definition->setDescription(      $struct->{description}           );
  $definition->setInputType(        $struct->{inputType}             );
  $definition->setRule(             $struct->{rule}                  );
  $definition->setRuleErrorMessage( $struct->{ruleErrorMessage}      );
  $definition->setOptionsType(      $struct->{optionsType}           );

  my $optionsData = '';
  $optionsData = Dumper($struct->{staticOptions}) if $struct->{optionsType} eq 'static';
  $optionsData = $struct->{methodOptions}         if $struct->{optionsType} eq 'method';
  $optionsData = $struct->{o2ContainerPath}       if $struct->{optionsType} eq 'o2ContainerPath';
  $definition->setOptionsData($optionsData);

  $definition->save();

  $obj->_saveProperties();

  $cgi->redirect( '/o2cms/System-PropertyEditor/editProperties?objectId=' . $obj->getParam('returnToObjectId') . '&includePropertyName=' . $definition->getMetaName() );
}
#--------------------------------------------------------------------------------
# edit properties on an object
sub editProperties {
  my ($obj) = @_;
  my %q = $obj->getParams();
  my $objectId = $q{objectId};

  if ( exists $q{displayAdvancedProperties} ) {
    $session->set( 'displayAdvancedProperties', $q{displayAdvancedProperties} );
    $session->save();
  }

  # properties affecting object
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  my @properties = $propertyMgr->getPropertiesById($objectId);

  # include new property in list (if it is not already present in list)
  my $alreadyIncluded = grep { $_->getName() eq $q{includePropertyName} } @properties;
  if ( $q{includePropertyName} && !$alreadyIncluded ) {
    my $property = $propertyMgr->newObject();
    $property->setName(         $q{includePropertyName} );
    $property->setObjectId(     $objectId               );
    $property->setOriginatorId( undef                   ); # since property is not really set in database yet
    push @properties, $property;
  }
  
  # known properties not affecting object
  my $propertyDefinitionMgr = $context->getSingleton('O2::Mgr::PropertyDefinitionManager');
  my @unusedDefinitions;
  foreach my $definition ( $propertyDefinitionMgr->getPropertyDefinitions($objectId) ) {
    next if grep { $_->getName() eq $definition->getPropertyName() } @properties;
    push @unusedDefinitions, $definition;
  }

  # properties set in parent objects
  my %parentProperties;
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my @path = $metaTreeMgr->getObjectPath($objectId);
  foreach my $part (@path) {
    foreach my $property ($propertyMgr->getPropertiesById( $part->getId() )) {
      $parentProperties{ $property->getName() }->{ $part->getId() } = $property;
    }
  }

  $obj->display(
    'editProperties.html',
    objectId                  => $objectId,
    parentProperties          => \%parentProperties,
    properties                => \@properties,
    unusedDefinitions         => \@unusedDefinitions,
    path                      => \@path,
    displayAdvancedProperties => $session->get('displayAdvancedProperties'),
  );
}
#--------------------------------------------------------------------------------
# ajax method for adding a new property
sub editPropertyRow {
  my ($obj) = @_;
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  my $property = $propertyMgr->getProperty($obj->getParam('objectId'), $obj->getParam('propertyName'));
  if (!$property) {
    $property = $propertyMgr->newObject();
    $property->setName(         $obj->getParam('propertyName') );
    $property->setObjectId(     $obj->getParam('objectId')     );
    $property->setOriginatorId( $obj->getParam('objectId')     );
  }
  $obj->display(
    'editPropertyRow.html',
    property => $property,
  );
}
#--------------------------------------------------------------------------------
sub saveProperties {
  my ($obj) = @_;
  $obj->_saveProperties();
  $obj->editProperties();
}
#--------------------------------------------------------------------------------
sub removeProperty {
  my ($obj) = @_;
  my %q = $obj->getParams();
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  $propertyMgr->deletePropertyValue( $q{objectId}, $q{propertyName} );
  $cgi->redirect("/o2cms/System-PropertyEditor/$q{nextUrl}");
}
#--------------------------------------------------------------------------------
# set properties based on parameters matching "property_<objectId>_<properyName>"
sub _saveProperties {
  my ($obj) = @_;
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  my %params = $obj->getParams();
  foreach my $name (keys %params) {
    my ($objectId, $propertyName) = $name =~ /property_(\d+)_(\w+)/;
    next unless $objectId;
    $propertyMgr->setPropertyValue( $objectId, $propertyName, $params{$name} );
  }
}
#--------------------------------------------------------------------------------
# returns all places where a property is used
sub _listPropertyUsage {
  my ($obj, $propertyName) = @_;
  
  my $propertyMgr = $context->getSingleton('O2::Mgr::PropertyManager');
  my $metaTreeMgr = $context->getSingleton('O2::Mgr::MetaTreeManager');
  
  my @properties;
  foreach my $property ( $propertyMgr->getPropertiesByName($propertyName) ) {
    my $object = $context->getObjectById( $property->getObjectId() );
    next unless $object;

    my @path = $metaTreeMgr->getObjectPath( $property->getObjectId() );
    next if grep {!defined $_} @path;
    next unless @path; # no path, probably a property pointing to a removed object

    push @properties, {
      property => $property,
      path     => \@path,
      sortKey  => join ('/', map { $_->getMetaName() } @path),
    };
  }

  return sort { $a->{sortKey} cmp $b->{sortKey} } @properties;
}
#--------------------------------------------------------------------------------
1;
