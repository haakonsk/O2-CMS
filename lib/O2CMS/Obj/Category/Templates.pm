package O2CMS::Obj::Category::Templates;

use strict;

use base 'O2CMS::Obj::Template::Directory';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub canAddObject {
  my ($obj, $fromContainer, $object) = @_;
  return $object->isa('O2CMS::Obj::Template') || $object->isa('O2CMS::Obj::TemplateDirectory');
}
#-------------------------------------------------------------------------------
sub canMove {
  my ($obj, $fromContainer, $toContainer) = @_;
  return 0; # can not move
}
#-------------------------------------------------------------------------------
sub getFullPath {
  my ($obj) = @_;
  my $path = $obj->getPath() or return;
  return $context->getSingleton('O2CMS::Mgr::TemplateManager')->resolveTemplatePath($path);
}
#-------------------------------------------------------------------------------
1;
