package O2CMS::Backend::Gui::Page::EditableTemplate;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#--------------------------------------------------------------------------------------------------
sub displayTemplate {
  my ($obj) = @_;
  my $template
    = $obj->getParam('templateId')
    ? $obj->getObjectByParam('templateId')
    : $context->getSingleton('O2::Mgr::Template::' . ucfirst $obj->getParam('templateType') . 'Manager')->newObject()
    ;
  $obj->display(
    'template.html',
    templateType    => $obj->getParam('templateType'),
    templateId      => $template->getId(),
    templateContent => ${ $template->getTemplateRef() },
  );
}
#--------------------------------------------------------------------------------------------------
sub saveTemplate {
  my ($obj) = @_;
  my $template = $obj->getObjectByParam('objectId');

  # write template to customerroot, if it was changed
  my $newText = $obj->_unifyText(  $obj->getParam('template')        );
  my $oldText = $obj->_unifyText(  ${ $template->getTemplateRef() }  );
  if ($newText ne $oldText) {
    my $path = $context->getEnv('O2CUSTOMERROOT') . $template->getPath();
    my ($dir) = $path =~ m|^(.*)/|;
    my $fileMgr = $context->getSingleton('O2::File');
    $fileMgr->mkPath($dir);
    $fileMgr->writeFile($path, $newText);
  }
  return 1;
}
#--------------------------------------------------------------------------------------------------
sub _unifyText {
  my ($obj, $text) = @_;
  $text =~ s/^\s+//s;   # remove leading spaces (textarea does not include first newline
  $text =~ s/\r\n/\n/g; # dos
  $text =~ s/\r/\n/g;   # mac
  return $text;
}
#--------------------------------------------------------------------------------------------------
1;
