package O2CMS::Mgr::TemplateManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context);
use O2CMS::Obj::Template;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    path => { type => 'varchar' }, # Relative to O2ROOT/O2CUSTOMERROOT etc
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# Returns Template object by file path
sub getObjectByPath {
  my ($obj, $path, %params) = @_;
  my %searchParams;
  $searchParams{metaStatus} = { like => '%' } if $params{includeTrashedObjects};
  my @objects = $obj->objectSearch(
    path => $path,
    %searchParams,
  );
  return unless @objects;
  return $objects[0];
}
#-------------------------------------------------------------------------------
sub resolveTemplatePath {
  my ($obj, $path) = @_;
  foreach my $root ($context->getRootPaths()) {
    my $fullPath = "$root/$path";
    $fullPath    =~ s{ // }{/}xmsg;
    return $fullPath if -e $fullPath;
  }
  return;
}
#-------------------------------------------------------------------------------
1;
