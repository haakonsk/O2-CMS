package O2CMS::Backend::Gui::Directory;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
sub sync {
  my ($obj) = @_;

  my $autoflush = $context->getSingleton('O2::Gui::Autoflush');
  $autoflush->enableAutoNewline();
  $autoflush->enableAutoScroll();
  $autoflush->printHeader(
    foregroundColor => '#af8',
    backgroundColor => 'black',
  );

  my $directory = $obj->getObjectByParam('directoryId');
  $directory->sync( debugLevel => 2 );

  $autoflush->printFooter();
}
#---------------------------------------------------------------------------------------
1;
