package O2CMS::Backend::Gui::System::FileDialog;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $config);

#--------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->display('popup.html');
}
#--------------------------------------------------------------------------------
# Takes two optional querystring parameters: filename=defaultFileName, folderId=defaultContainerId
sub saveAsDialog {
  my ($obj) = @_;
  $obj->display('saveAsDialog.html');
}
#--------------------------------------------------------------------------------
sub listFolder {
  my ($obj) = @_;
  
  # Use Installation object as folder unless folderId given
  my $folderId = $obj->getParam('folderId');
  my $folder;
  if ($folderId > 0) {
    $folder = $context->getObjectById($folderId);
  }
  else {
    ($folder) = $context->getSingleton('O2CMS::Mgr::InstallationManager')->objectSearch(-limit => 1);
  }
  
  # List path to folder
  my @path = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectPathTo($folder);
  push @path, $folder;
  
  my @files;
  foreach my $object ( sort _sortFiles $folder->getChildren() ) {
    push @files, $object;
  }
  
  $obj->display(
    'listFolder.html',
    path  => \@path,
    files => \@files,
  );
}
#--------------------------------------------------------------------------------
sub _sortFiles {
  return lc ( $a->getMetaName() ) cmp lc ( $b->getMetaName() ) if $a->isa('O2CMS::Obj::Category') && $b->isa('O2CMS::Obj::Category');
  return -1 if  $a->isa('O2CMS::Obj::Category') && !$b->isa('O2CMS::Obj::Category');
  return  1 if !$a->isa('O2CMS::Obj::Category') &&  $b->isa('O2CMS::Obj::Category');
  return lc ( $a->getMetaName() ) cmp lc ( $b->getMetaName() ) if $a->isa('O2::Obj::Image') && $b->isa('O2::Obj::Image');
  return  1 if  $a->isa('O2::Obj::Image') && !$b->isa('O2::Obj::Image');
  return -1 if !$a->isa('O2::Obj::Image') &&  $b->isa('O2::Obj::Image');
  return lc ( $a->getMetaName() ) cmp lc ( $b->getMetaName() );
}
#--------------------------------------------------------------------------------
sub _object2hash {
  my ($obj, $object) = @_;
  my $iconRoot = $config->get('o2.adminImageRootUrl') . '/system/classIcons';
  my $iconFile = $object->getMetaClassName();
  $iconFile =~ s|::|-|g;
  return {
    id          => $object->getId(), 
    name        => $object->getMetaName(), 
    iconUrl     => "$iconRoot/$iconFile.gif", 
    className   => $object->getMetaClassName(),
    isContainer => $object->isContainer() ? 1 : 0,
    fileUrl     => $object->can('getFileUrl') ? $object->getFileUrl() : '',
  };
}
#--------------------------------------------------------------------------------
1;
