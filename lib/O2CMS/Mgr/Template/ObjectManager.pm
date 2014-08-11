package O2CMS::Mgr::Template::ObjectManager;

use strict;

use base 'O2CMS::Mgr::TemplateManager';

use O2 qw($context);
use O2CMS::Obj::Template::Object;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template::Object',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    usableClasses => { type => 'varchar', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub getModelClassName {
  return 'O2CMS::Obj::Template::Object';
}
#-------------------------------------------------------------------------------
# lists templates available for a class
# parameters: class         => name of class (i.e. O2CMS::Obj::Article)
#             templateMatch => search pattern for relative template path (i.e. *frontpage/box*.html)
sub queryTemplates {
  my ($obj, %params) = @_;
  
  my @objects = $obj->getObjectTemplatesByClassName( $params{class} );
  return grep  { $_->getFullPath() && -e $_->getFullPath() }  @objects unless $params{templateMatch};
  
  my %objects;
  my @templateMatches = split /\|/, $params{templateMatch};
  foreach my $match (@templateMatches) {
    $match =~ s{ \* }{.*}xmsg;
    $match =~ s{ \. }{\\.}xmsg;
    foreach my $object (@objects) {
      $objects{ $object->getId() } = $object if $object->getPath() =~ m{ $match }xms;
    }
  }
  return grep  { -e $_->getFullPath() }  values %objects;
}
#-------------------------------------------------------------------------------
sub getObjectTemplatesByClassName {
  my ($obj, $className) = @_;
  
  # Object templates that are valid for a super class should also be valid for "this" class
  my @classNames = ($className);
  push @classNames, $context->getSingleton('O2::Util::ObjectIntrospect', className => $className)->getInheritedClasses();
  
  return $obj->objectSearch(
    usableClasses => { in => \@classNames },
  );
}
#-------------------------------------------------------------------------------
1;
