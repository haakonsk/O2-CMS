package O2CMS::Backend::Gui::MultiMedia::Player;

# General backend O2 multimedia player

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#-------------------------------------------------------------
sub init {
  my ($obj, %params) = @_;
  my $objectId = $params{objectId} || $obj->getParam('objectId');
  my $object   = $context->getObjectById($objectId);
  print "An error occured" unless $object;
  
  $obj->display(
    'init.html',
    mediaUrl => $object->getFileUrl(),
  );
}
#------------------------------------------------------------
1;
