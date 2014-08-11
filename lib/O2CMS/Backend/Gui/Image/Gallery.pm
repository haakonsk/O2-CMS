package O2CMS::Backend::Gui::Image::Gallery;

use strict;

use base 'O2CMS::Backend::Gui::Universal';

use O2 qw($context);

#-------------------------------------------------------------------------------
sub editTitlesAndDescriptions {
  my ($obj) = @_;
  my $gallery = $context->getObjectById( $obj->getParam('objectId') );
  $obj->error('Image Gallery not found') unless $gallery;
  $obj->display(
    'o2://var/templates/O2/Obj/Image/Gallery/editTitlesAndDescriptions.html',
    gallery => $gallery,
  );
}
#-------------------------------------------------------------------------------
1;
