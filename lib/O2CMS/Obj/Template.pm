package O2CMS::Obj::Template;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-------------------------------------------------------------------------------
# returns full path to template
sub getFullPath {
  my ($obj) = @_;
  my $path = $obj->getPath();
  return unless $path;
  return $obj->getManager()->resolveTemplatePath($path);
}
#-------------------------------------------------------------------------------
sub getPrettyName {
  my ($obj) = @_;
  my $name = $obj->getMetaName();
  $name    =~ s{ [.]html? \z }{}xms;
  return ucfirst $name;
}
#-------------------------------------------------------------------------------
sub getFileName {
  my ($obj) = @_;
  my ($file) = $obj->getPath() =~ m{ [\\/:]([^\\/:]+) \z }xms;
  return $file;
}
#-------------------------------------------------------------------------------
sub getTemplateRef {
  my ($obj) = @_;
  my $path     = $obj->getPath()                                || '';
  my $fullPath = $obj->getManager()->resolveTemplatePath($path) || '';
  my $error = "[TEMPLATE NOT FOUND! path: '$path',objectId: ".$obj->getId().", fullPath: $fullPath]";
  return \$error unless $fullPath;
  return $context->getSingleton('O2::File')->getFileRef($fullPath);
}
#-------------------------------------------------------------------------------
sub parse {
  my ($obj, %params) = @_;
  
  require O2::Template;
  my $template = O2::Template->newFromString( $obj->getTemplateRef() );
  $template->setLocale( $context->getLocale() );

  return $template->parse(%params);
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-------------------------------------------------------------------------------
1;
