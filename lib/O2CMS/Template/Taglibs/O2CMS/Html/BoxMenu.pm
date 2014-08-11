package O2CMS::Template::Taglibs::O2CMS::Html::BoxMenu;

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  %methods = (
    %methods,
    BoxMenu     => 'postfix',
    addMenuItem => '',
  );
  
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub BoxMenu {
  my ($obj,%params) = @_;
  
  $obj->{id} = $params{BoxMenuId} || 'BOXMENU' . $obj->_getRandomId();
  $obj->{selectedIdx} = 1;
  $obj->addJsFile(  file => 'boxmenu'                    );
  $obj->addCssFile( file => $params{cssFile} || 'boxMenu');
  $obj->{defaultMenuIcon} = exists ( $params{icon}       ) ? $params{icon}       : undef;
  $obj->{expandMenuIcon}  = exists ( $params{expandIcon} ) ? $params{expandIcon} : undef;
  
  # setting up the JS init code
  $obj->addJs(content => "var $obj->{id} = null;");
  
  my $animateBool = 'false';
  $animateBool = 'true' if exists ( $params{animate} ) && $params{animate} != 0 &&  lc ( $params{animate} ) ne 'false';
  
  my @jsProps;
  push @jsProps,'height:"' . ($params{height} || '100%') . '"';
  push @jsProps,'width:"'  . ($params{width}  || '100%') . '"';
  
  my $jsProps = '{' . join (',', @jsProps) . '}';
  
  $obj->addJs(
    where   => 'onLoad',
    content => qq{
      $obj->{id} = new BoxMenu("$obj->{id}", document, $jsProps);
      $obj->{id}.animateMenu = $animateBool;
      var $obj->{id}_menuItems = new Array();
    }
  );
  $obj->{parser}->pushMethod('addMenuItem' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('addMenuItem' => $obj);
  if ($obj->{selectedIdx}) {
    $obj->addJs(
      where   => 'onLoad',
      content => qq{ $obj->{id}.selectByIdx($obj->{selectedIdx}); }
    );
  }
  
  return '';
}
#--------------------------------------------------------------------------------------------
sub addMenuItem {
  my ($obj, %params) = @_;
  
  $obj->{menuItemCounter}++;
  
  my $icon = $params{icon} || $obj->{defaultMenuIcon};
  my $expandIcon = $params{expandIcon}    ? ",'$params{expandIcon}'"    : undef;
  $expandIcon  ||= $obj->{expandMenuIcon} ? ",'$obj->{expandMenuIcon}'" : '';
  
  # Which add method should we use?
  my ($addMethod, $bodyKey);
  if (exists $params{elementId}) {
    $addMethod = 'addFromElement';
    $bodyKey   = 'elementId';
  }
  elsif (exists $params{url}) {
    $addMethod = 'addRefToUrl';
    $bodyKey   = 'url';
  }
  elsif (exists $params{body}) {
    $addMethod = 'add';
    $bodyKey   = 'body';
  }
  else {
    $addMethod = 'add';
    $bodyKey   = 'content';
  }
  $params{$bodyKey} =~ s{ \n }{\\n}xmsg;
  $params{$bodyKey} =~ s{ \" }{\\\"}xmsg;
  
  if (exists $params{selected}) {
    $obj->{selectedIdx} = $obj->{menuItemCounter};
  }
  
  $obj->addJs(
    where   => 'onLoad',
    content => qq{
      // addMenuItem init code for $obj->{id}
      $obj->{id}_menuItems.push($obj->{id}.$addMethod("$params{title}", "$icon", "$params{$bodyKey}" $expandIcon));
    }
  );
  
  return '';
}
#--------------------------------------------------------------------------------------------
1;
