package O2CMS::Template::Taglibs::O2CMS::Html::PopupMenu;

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  
  %methods = (
    %methods,
    PopupMenu    => 'postfix',
    addMenuItem  => 'postfix',
    addSeparator => '',
  );

  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub PopupMenu {
  my ($obj, %params) = @_;
  
  $obj->{subCounter} = 0;
  $obj->{id} = $params{menuId} || 'DOMMENU' . $obj->_getRandomId();
  
  $obj->addJsFile(  file => 'dommenu'                     );
  $obj->addCssFile( file => $params{cssFile} || 'dommenu' );

  $obj->addJs( content => "var $obj->{id} = null;" );
  
  $obj->{colspan}        = 1; # =1  of because frameHeader title cell
  $obj->{currMenuItemId} = $obj->{id};
  $obj->{parser}->_parse( \$params{content} );
  
  my $jsInit = '';
  if (lc ( $params{element} ) eq 'contextmenu') {
    $jsInit .= "$obj->{id} = new DOMPopupMenu(this.document);";
  }
  else {
    $jsInit .= "$obj->{id} = new DOMMenu('" . ($params{element} || $obj->{id}) . "',null,null,'down');";
  }
  
  if (exists $params{cssClassname}) {
    $jsInit .= "$obj->{id}.setClassName('$params{cssClassname}');\n";
  }
  elsif (exists $params{cssFile}) {
    $jsInit .= "$obj->{id}.setClassName('$params{cssFile}');\n";
  }
  
  $obj->addJs(where => 'onLoad', content => qq{
    $jsInit
    $params{content}
    // $obj->{id}.showMenu(100,100);
  });

  return '';
}
#--------------------------------------------------------------------------------------------
sub addMenuItem {
  my ($obj, %params) = @_;
  $obj->{subCounter}++;
  # Do we have sub menu items for this menu item?
  my $thisMenuId = $obj->{currMenuItemId} . '_' . $obj->{subCounter};
  if ($params{content}) {
    my $parentId = $obj->{currMenuItemId};
    $obj->{currMenuItemId} = $thisMenuId;
    $obj->{parser}->_parse( \$params{content} );
    $obj->{currMenuItemId} = $parentId;
  }
  
  # Support for hoverAction
  my $hover = '';
  $hover = qq{$thisMenuId.setHoverAction("$params{hoverAction}");\n} if exists $params{hoverAction};
  
  my $icon = $params{icon} ? ",'$params{icon}'" : '';
  my $direction   = 'null';
  my $hoverAction = 'null';
  my $dragId = $params{dragId} ? '"' . $params{dragId} . '"' : 'null';
  return qq{var $thisMenuId = $obj->{currMenuItemId}.addMenuItem(["$params{name}"$icon], "$params{action}", $direction, $hoverAction, $dragId);\n$hover$params{content}};
}
#--------------------------------------------------------------------------------------------
sub addSeparator {
  my ($obj, %params) = @_;
  return "$obj->{currMenuItemId}.addSeperator();";
}
#--------------------------------------------------------------------------------------------
1;
