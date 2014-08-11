package O2CMS::Backend::Gui::Page::ObjectTemplate;

# Gui module for editing O2CMS::Obj::Template::Object templates (mainly list of classes that may use this template)

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#--------------------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  my $template
    = $obj->getParam('objectId')
    ? $obj->getObjectByParam('objectId')
    : $context->getSingleton('O2::Mgr::Template::ObjectManager')->newObject()
    ;
  
  $obj->display(
    'edit.html',
    template      => $template,
    classNames    => [ $context->getSingleton('O2::Mgr::ClassManager')->getClassNames() ],
    usableClasses => { map { $_ => 1 } $template->getUsableClasses() },
    objectId      => $obj->getParam('objectId'),
  );
}
#--------------------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  my $template
    = $obj->getParam('objectId')
    ? $obj->getObjectByParam('objectId')
    : $context->getSingleton('O2::Mgr::Template::ObjectManager')->newObject()
    ;
  $template->setMetaName(      $obj->getParam('name')          );
  $template->setUsableClasses( $obj->getParam('usableClasses') );
  
  if (!$template->getId()) {
    my $name = $template->getMetaName();
    if ($name !~ m{ [.]html \z }xms) {
      $name .= '.html';
      $template->setMetaName($name);
    }
    $template->setMetaParentId( $obj->getParam('parentId') );
    
    my $templateDirectory = $obj->getObjectByParam('parentId');
    $template->setPath( $templateDirectory->getPath() . "/$name" );
    
    my $directoryPath = $templateDirectory->getFullPath() or die "Didn't find directory for $templateDirectory";
    $context->getSingleton('O2::File')->writeFile("$directoryPath/$name", '');
  }
  
  $template->save();
  
  return {
    objectId => $template->getId(),
  };
}
#--------------------------------------------------------------------------------------------------
1;
