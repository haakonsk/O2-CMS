package O2CMS::Template::Taglibs::O2CMS::Html::TabLayer;

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);

  $obj->addJsFile( file => 'tabLayer' );
  
  %methods = (
    %methods,
    TabLayer => 'postfix',
    tabLayer => 'postfix',
    addTab   => '',
  );

  return $obj, %methods;
}
#--------------------------------------------------------------------------------------------
sub TabLayer {
  my ($obj, %params) = @_;
  return $obj->tabLayer(%params);
}
#--------------------------------------------------------------------------------------------
sub tabLayer {
  my ($obj, %params) = @_;
  
  $obj->addCssFile( file => $params{cssFile} || 'tabLayer' );
  
  my $tabLayerName = ($params{name} || $params{id})  ||  'tabLayer' . $obj->_getRandomId();
  
  my %props = (
    tabOverLap         => 'int',
    showCloseButton    => 'bool',
    tabShowCloseButton => 'bool',
  );

  my $jsPropName = $tabLayerName . '_props';
  my $jsProps    = "var $jsPropName = new Array();\n";
  foreach (keys %props) {
    if (exists $params{$_}) {
      my $value = $params{$_};
      $value = "'$value'" if $props{$_} eq 'string';
      if ($props{$_} eq 'bool') { 
        $value = 'false' if $value == 0;
        $value = 'true'  if $value == 1;
      }

      $jsProps .= $jsPropName . "['$_'] = $value;\n";
    }
  }

  $obj->addJs(
    where   => 'onLoad',
    content => <<"END"
      $jsProps
      $tabLayerName = new TabLayer("$tabLayerName", null, $jsPropName);
END
  );

  $obj->addJs( content => "var $tabLayerName = null;" );
  $obj->{tabLayerName} = $tabLayerName;

  $obj->{parser}->_parse( \$params{content} );

  my $style = $params{style} ? "style='$params{style}'" : '';
  $obj->addJs(
    where   => 'onLoad',
    content => "$tabLayerName.realignTabs();",
  );

  return "<div id='$tabLayerName' $style>$params{content}</div>";
}
#--------------------------------------------------------------------------------------------
sub addTab {
  my ($obj, %params) = @_;
  $obj->{tabCount}++;
  my $contentIds;
  my $html = '';
  if ($params{contentId}) {
    $contentIds = ",'$params{contentId}'";
  }
  elsif ($params{content}) {
    $obj->{parser}->_parse( \$params{content} );
    my $id = $params{id} || "tab$obj->{tabCount}";
    $contentIds = ",'$id'";
    $html = "<div id='$id'>$params{content}</div>";
  }
  my $tabName = $params{jsName} || "$obj->{tabLayerName}_tab_$obj->{tabCount}";
  $obj->addJs( content => "var $tabName = null;" );
  $obj->addJs(
    where   => 'onLoad',
    content => "$tabName = $obj->{tabLayerName}.addTab('$params{name}' $contentIds);", # Notice: Value of $contentIds starts with a comma
  );
  if ($params{selected}) {
    $obj->addJs(
      where   => 'onLoad',
      content => "$obj->{tabLayerName}.selectTab($tabName.id);",
    );
  }
  if ($params{notCloseAble}) {
    $obj->addJs(
      where   => 'onLoad',
      content => "$tabName.setCloseAble(false);",
    );
  }
  if ($params{preAction}) {
    $obj->addJs(
      where   => 'onLoad',
      content => "$tabName.addPreAction(\"$params{preAction}\");",
    );
  }
  return $html;
}
#--------------------------------------------------------------------------------------------
1;
