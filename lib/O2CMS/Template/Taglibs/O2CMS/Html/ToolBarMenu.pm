package O2CMS::Template::Taglibs::O2CMS::Html::ToolBarMenu;

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  
  %methods = (
    %methods,
    toolBarMenu  => 'postfix',
    addItem      => '',
    addCell      => '',
    addSeparator => '',
  );

  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub toolBarMenu {
  my ($obj, %params) = @_;
  
  my $status = $obj->addCssFile( file => $params{cssFile} || 'toolBarMenu' );
  die "Could not load CSS file 'toolBarMenu'" if $status ne '';

  my $props = {};
  my $propLine = '';
  foreach (keys %{$props}) {
    $obj->{parser}->parseVars( \$params{$_} ) if exists $params{$_};
    if (exists $params{$_}) {
      $propLine .= qq{$_="$params{$_}" };
    }
    else {
      $propLine .= qq{$_="$props->{$_}" };
    }
  }
  $obj->{parser}->_parse( \$params{content} );
  return qq{<div class="o2Toolbar" $propLine>$params{content}</div>};
}
#--------------------------------------------------------------------------------------------
sub addItem {
  my ($obj, %params) = @_;
  my $action = '';
  if ($params{action}) {
    $action = qq{ onClick = "$params{action}"};
  }
  my $buttonIcon = $params{icon} ? " style='background-image: url($params{icon})'" : '';
  my $buttonId   = $params{id}   ? " id='$params{id}'"                             : '';
  return "<div class='o2ToolbarButton' $buttonId $action $buttonIcon>$params{name}</div>";
}
#--------------------------------------------------------------------------------------------
sub addCell {
  my ($obj, %params) = @_;
  return '<div class="o2ToolbarCell">'.$params{content}.'</div>';
}
#--------------------------------------------------------------------------------------------
sub addSeparator {
  my ($obj,%params) = @_;
  my $separatorWidth   = $params{width} ? " style='width: $params{width}'" : '';
  return "<div class='o2ToolbarSeparator' $separatorWidth></div>";
}
#--------------------------------------------------------------------------------------------
1;
