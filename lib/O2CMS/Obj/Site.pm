package O2CMS::Obj::Site;

# Class representing a website

use strict;

use base 'O2CMS::Obj::WebCategory';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub getProtocol {
  my ($obj) = @_;
  return 'http';
}
#-------------------------------------------------------------------------------
# returns full directory path. Overridden from O2CMS::Obj::WebCategory
sub getDirectoryPath {
  my ($obj) = @_;
  return $obj->getDirectoryName();
}
#-------------------------------------------------------------------------------
sub getDirectoryName {
  my ($obj) = @_;
  my $path = $obj->getModelValue('directoryName');
  return $obj->getId() ? $path : '';
}
#-------------------------------------------------------------------------------
# returns full url. Overridden from O2CMS::Obj::WebCategory
sub getUrl {
  my ($obj) = @_;
  return $obj->getProtocol() . '://' . $obj->getHostname() . '/';
}
#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return !$object->isa('O2CMS::Obj::Site');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return $toContainer->isa('O2CMS::Obj::Trashcan') || $toContainer->isa('O2CMS::Obj::Installation');
}
#-------------------------------------------------------------------------------
sub getUsedLocales {
  my ($obj) = @_;
  return $obj->getAvailableLocales();
}
#-------------------------------------------------------------------------------
sub setHostname {
  my ($obj, $hostname) = @_;
  $obj->setModelValue('hostname', $hostname);
  
  # Make sure directoryName is set:
  my $directoryName = $obj->SUPER::getDirectoryName();
  if (!$directoryName) {
    $directoryName  = $context->getEnv('O2CUSTOMERROOT');
    $directoryName  =~ s{ o2 /? \z }{}xms;
    $directoryName .= $hostname;
    $obj->setDirectoryName($directoryName);
  }
}
#-------------------------------------------------------------------------------
1;
