package O2CMS::Frontend::Gui::System::Documentation::Taglibs;

use strict;

use base 'O2::Gui::System::Documentation::Taglibs';

use O2 qw($context $cgi);

#--------------------------------------------------------------------------------------------------
sub _getModules {
  my ($obj) = @_;
  my @modules = $obj->SUPER::_getModules();
  push @modules, qw(
    O2CMS::ApplicationFrame
    O2CMS::Html::BoxMenu
    O2CMS::Html::Form::DragList
    O2CMS::Html::Form::RichTextArea
    O2CMS::Html::PopupMenu
    O2CMS::Html::TabLayer
    O2CMS::Html::TreeMenu
    O2CMS::Page
    O2CMS::Publisher
  );
  return sort @modules;
}
#--------------------------------------------------------------------------------------------------
1;
