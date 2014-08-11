package O2CMS::Backend::Gui::Category::CategoryEditor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
sub create {
  my ($obj) = @_;
  my $parentId  = $obj->getParam('parentId');
  my $className = $obj->getParam('className');
  my $category = $context->getSingleton('O2::Mgr::UniversalManager')->newObjectByClassName($className);
  $category->setMetaParentId($parentId);
  $obj->_edit($category);
}
#---------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  my $categoryId = $obj->getParam('categoryId');
}
#---------------------------------------------------------------------------------------
sub _edit {
  my ($obj, $category) = @_;
  my $className = $category->getMetaClassName();
  $obj->display('edit.html');
}
#---------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
}
#---------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg) = @_;
  print "<font color=blue>$msg</font><br>";
}
#---------------------------------------------------------------------------------------
1;
