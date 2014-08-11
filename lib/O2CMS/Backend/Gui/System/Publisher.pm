package O2CMS::Backend::Gui::System::Publisher;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub getObjectUrl {
  my ($obj) = @_;
  my $object = $context->getObjectById( $obj->getParam('objectId') ) or die 'Object not found';
  
  if ($object->getMetaClassName() eq 'O2::Obj::File') { # only for files, not subclasses like image or video. vonheim@20070208
    return {
      url  => '/o2/File-Download/view?objectId=' . $object->getId(),
      name => $object->getMetaName(),
    };
  }
  
  return {
    url  => $context->getSingleton('O2CMS::Publisher::UrlMapper')->generateUrl(object => $object),
    name => $object->getMetaName(),
  };
}
#-------------------------------------------------------------------------------
sub getImageHtml {
  my ($obj) = @_;
  my %params = $obj->getParams();
  my $html;
  
  my $image = $context->getObjectById( $params{objectId} );
  if ($params{microObjectTemplate}) {
    $html = $obj->display(
      "o2://var/templates/frontend/microObjects/image/$params{microObjectTemplate}",
      object       => $image,
      __doNotPrint => 1,
    );
  }
  else {
    $html = "<img src='" . $image->getFileUrl() . "' alt=''>";
  }
  
  return {
    html => $html,
  };
}
#-------------------------------------------------------------------------------
sub getAvailableMicroObjectTemplates {
  my ($obj) = @_;
  return {
    availableTemplates => [  $obj->_getMicroObjectTemplates( $obj->getParam('objectType') )  ],
  };
}
#-------------------------------------------------------------------------------
sub _getMicroObjectTemplates {
  my ($obj, $objectType) = @_;
  my $fileMgr        = $context->getSingleton('O2::File');
  my $O2ROOT         = $context->getEnv('O2ROOT');
  my $O2CUSTOMERROOT = $context->getEnv('O2CUSTOMERROOT');
  my %templates;
  %templates =              map  { $_ => 1 }  $fileMgr->scanDir("$O2ROOT/var/templates/frontend/microObjects/$objectType",         '*.html$')  if -e "$O2ROOT/var/templates/frontend/microObjects/$objectType";
  %templates = (%templates, map  { $_ => 1 }  $fileMgr->scanDir("$O2CUSTOMERROOT/var/templates/frontend/microObjects/$objectType", '*.html$')) if -e "$O2CUSTOMERROOT/var/templates/frontend/microObjects/$objectType";
  return keys %templates;
}
#-------------------------------------------------------------------------------
1;
