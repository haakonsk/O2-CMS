package O2CMS::Template::Taglibs::O2CMS::Html::TreeMenu;

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  %methods = (
    %methods,
    TreeMenu       => 'postfix',
    TreeMenuFolder => 'postfix',
    TreeMenuItem   => 'postfix',
  );
  
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub TreeMenu {
  my ($obj,%params) = @_;
  
  my $type = $params{type} || 'Tree';
  $obj->addJsFile(file => 'componentBase');
  $obj->addJsFile(file => 'Tree');
  if ($type eq 'MenuEditorTree') {
    $obj->addJsFile( file => 'MenuEditorTree' );
    $obj->addJsFile( file => 'dragDrop'       );
  }
  
  $obj->{TREEMENULEVEL}   = 0;
  $obj->{FOLDERIDCOUNTER} = 0;
  $obj->{CURRENTFOLDERID} = [];
  
  $obj->{id} = $params{id} || $params{TreeId} || 'TREEMENU' . $obj->_getRandomId();
  
  $obj->addCssFile( file => $params{cssFile} ) if $params{cssFile};
  $obj->addJs(                    content => "var $obj->{id} = null;"                             );
  $obj->addJs( where => 'onLoad', content => "\n  $obj->{id} = getComponentById('$obj->{id}');\n" );
  
  $obj->{parser}->_parse( \$params{content} );
  my $jsInit = '';
  
  if (exists $params{cssFile}) {
    #overriding the default class name for this tree menu
    $jsInit .= "_defaultTreemenuCSSClassname = '$params{cssFile}';\n";
  }
  
  $obj->addJs(
    where   => 'onLoad',
    content => qq{$jsInit},
  );
  return qq{<div component="$type" id="$obj->{id}"></div>};
}
#--------------------------------------------------------------------------------------------
sub TreeMenuFolder {
  my ($obj, %params) = @_;
  
  $obj->{parentId} = $obj->{TREEMENULEVEL} > 0 ? '"' . $obj->{id} . "_FOLDER" . $obj->{FOLDERIDCOUNTER} . '"' : 'null';
  $obj->{parentId} = $obj->{CURRENTFOLDERID}->[-1] || 'null';
  
  $obj->{FOLDERIDCOUNTER}++;
  $obj->{TREEMENULEVEL}++;
  $obj->{folderId} = "'$obj->{id}_FOLDER$obj->{FOLDERIDCOUNTER}'";
  
  push @{ $obj->{CURRENTFOLDERID} }, $obj->{folderId};
  
  $params{title} =~ s{ ( [^\\] )  \" }{$1\\\"}xmsg;
  $params{title} =~ s{            \n }{\\n}xmsg;
  $obj->addJs(where => 'onLoad', content => "  $obj->{id}.addFolder($obj->{parentId}, $obj->{folderId}, \"$params{title}\");");
  $obj->{parser}->_parse( \$params{content} );
  $obj->{TREEMENULEVEL}--;
  pop @{ $obj->{CURRENTFOLDERID} };
  
  my $expanded = $obj->{parser}->findVar( $params{expanded} );
  if ($expanded) {
    $obj->addJs(
      where   => 'onLoad',
      content => "$obj->{id}.expand( $obj->{folderId} );",
    );
  }
  
  return '';
}
#--------------------------------------------------------------------------------------------
sub TreeMenuItem {
  my ($obj, %params) = @_;
  
  $obj->{parentId} = $obj->{CURRENTFOLDERID}->[-1];
  $obj->{parser}->_parse( \$params{content} );
  $params{content} =~ s{ ( [^\\] )  \" }{$1\\\"}xmsg;
  $params{content} =~ s{            \n }{\\n}xmsg;
  $obj->addJs(where => 'onLoad', content => "  $obj->{id}.addFile($obj->{parentId}, \"$params{content}\");");
  
  return '';
}
#--------------------------------------------------------------------------------------------
1;
