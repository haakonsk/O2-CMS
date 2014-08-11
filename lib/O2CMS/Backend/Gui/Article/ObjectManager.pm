package O2CMS::Backend::Gui::Article::ObjectManager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($config);

#---------------------------------------------------------------------------------------
sub insertObjectPopup {
  my ($obj) = @_;
  $obj->display(
    'insertObjectPopup.html',
    defaultLinkTarget => $config->get('xinha.defaultLinkTarget') || '',
  );
}
#---------------------------------------------------------------------------------------
1;
