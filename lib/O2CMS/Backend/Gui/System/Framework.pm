package O2CMS::Backend::Gui::System::Framework;

use strict;

use constant PROFILING => 'off';

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub setupFramework { 
  my ($obj) = @_;
  my %classes;

  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');
  foreach my $className ($classMgr->getClassNames()) {
    my $class = $classMgr->getObjectByClassName($className);
    $classes{$className} = {
      editUrl => $class->getEditUrl(),
      newUrl  => $class->getNewUrl(),
    };
  }
  $obj->display(
    'setupFramework.html',
    classes    => \%classes,
    trashcanId => $context->getTrashcanId(),
  );
}
#--------------------------------------------------------------------------------------------
sub setupTop {
  my ($obj, %params) = @_;
  my $installation = $context->getSingleton('O2::Mgr::MetaTreeManager')->getObjectByPath('/Installation');
  $obj->display(
    'frameTop.html',
    installation => $installation,
    %params,
  );
}
#--------------------------------------------------------------------------------------------
sub setupMiddle {
  my ($obj, %params) = @_;
  $obj->display('frameMiddle.html', %params);
}
#--------------------------------------------------------------------------------------------
sub setupBottom {
  my ($obj, %params) = @_;
  $obj->display('frameBottom.html', %params);
}
#--------------------------------------------------------------------------------------------
sub setupLeft {
  my ($obj, %params) = @_;
  $obj->display('frameLeft.html', %params);
}
#--------------------------------------------------------------------------------------------
sub setupRight {
  my ($obj, %params) = @_;
  $obj->display('frameRight.html', %params);
}
#--------------------------------------------------------------------------------------------
sub setupRecent {
  my ($obj, %params) = @_;
  $obj->display('frameRecent.html', %params);
}
#--------------------------------------------------------------------------------------------
sub documentController {
  my ($obj, %params) = @_;
  $obj->display('documentController.html', %params);
}
#--------------------------------------------------------------------------------------------
1;
