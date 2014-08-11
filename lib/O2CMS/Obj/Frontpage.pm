package O2CMS::Obj::Frontpage; # Class representing a (web) frontpage

use strict;

use base 'O2CMS::Obj::Page';

use O2 qw($context $config);

#------------------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0;
}
#------------------------------------------------------------------------------------------
sub isPageCachable {
  my ($obj) = @_;
  my $value = $obj->getPropertyValue('isPageCachable');
  return $value eq 'yes' || $value eq '1';
}
#------------------------------------------------------------------------------------------
sub setPageCachable {
  my ($obj, $isCachable) = @_;
  $obj->save() unless $obj->getId(); # Got to have an id!
  if ($isCachable eq 'inherit') {
    $obj->deletePropertyValue('isPageCachable');
  }
  else {
    $obj->setPropertyValue('isPageCachable', $isCachable);
  }
}
#------------------------------------------------------------------------------------------
sub deleteCachedPage {
  my ($obj) = @_;
  return $context->getSingleton('O2CMS::Publisher::PageCache')->delCached($obj);
}
#------------------------------------------------------------------------------------------
sub isRevisionable {
  return 1;
}
#------------------------------------------------------------------------------------------
sub delete {
  my ($obj) = @_;
  $obj->deleteCachedPage();
  $obj->SUPER::delete();
}
#------------------------------------------------------------------------------------------
sub deletePermanently {
  my ($obj) = @_;
  $obj->deleteCachedPage();
  $obj->SUPER::deletePermanently();
}
#------------------------------------------------------------------------------------------
1;
