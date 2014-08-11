package O2CMS::Backend::Gui::Template::Editor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#-------------------------------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  
  my $templateId = $obj->getParam('objectId');
  return unless $templateId;
  
  my $template = $context->getObjectById($templateId);
  
  $obj->_edit($template);
}
#-------------------------------------------------------------------------------------------------------------
sub _edit {
  my ($obj, $template) = @_;
  
  $obj->display(
    'editObject.html',
    template => $template,
  );
}
#-------------------------------------------------------------------------------------------------------------
sub create {
  print "Not implemented yet.";
}
#-------------------------------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  
  my $templateId = $obj->getParam('objectId');
  return unless $templateId;
  
  my $template = $context->getObjectById($templateId);
  my $newSource = $obj->getParam('templateSource');
  
  if ($newSource) {
    my $fileMgr = $context->getSingleton('O2::File');
    $fileMgr->writeFile( $template->getFullPath(), $newSource );
    $fileMgr->closeFile();
  }
  
  $obj->_edit($template);
}
#-------------------------------------------------------------------------------------------------------------
1;
