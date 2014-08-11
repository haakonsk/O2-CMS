package O2CMS::Template::Taglibs::O2CMS::Html::Form::DragList;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

use O2 qw($context);

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    dragList   => 'postfix',
    objectItem => 'postfix',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub dragList {
  my ($obj, %params) = @_;

  $params{id} ||= $params{name};
  $obj->addJsFile(  file => 'componentBase' );
  $obj->addJsFile(  file => 'dragDrop'      );
  $obj->addJsFile(  file => 'List'          );
  $obj->addJsFile(  file => 'DragList'      );
  $obj->addCssFile( file => 'dragList'      );
  $obj->{parser}->parseVars( \$params{id} );
  $obj->{listItems}      = [];
  $obj->{textMethodName} = $params{textMethodName};
  $obj->{iconSize}       = $params{iconSize};

  $obj->{parser}->pushMethod('inputHint', $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('inputHint', $obj);
  my $post = $obj->{parser}->getProperty('inputHintHtml');
  $obj->{parser}->setProperty('inputHintHtml', undef);
  delete $params{content};

  # Default params
  $params{class}           ||= 'dragList';
  $params{allowClass}      ||= '*';
  $params{replace}         ||= 'yes';
  $params{reorganize}      ||= 'yes';
  $params{unique}          ||= 'yes';
  $params{removeOnDragEnd} ||= 'yes';

  my $onChange = $params{onChange};
  $onChange   .= '; ' if $onChange && $onChange !~ m{ ; \s* \z }xms;
  $params{onChange} = $onChange . $obj->{parser}->getProperty('formOnChange');

  my $items = delete $params{items};
  my $label = delete $params{label};
  my $attrs = $obj->_packTagAttribs(%params);

  my $html = '';
  my $useTable = $obj->{parser}->getProperty('isFormTable');
  my $trOrDiv  = $label && $useTable ? 'tr' : 'div';
  my $tdOrSpan = $label && $useTable ? 'td' : 'div';
  if ($label) {
    $html  = "<$trOrDiv class='o2InputWrapper o2DragList'>\n" unless $obj->{parser}->getProperty('manualTrTdTags');
    $html .= "<td class='o2Label'>" if $useTable;
    $html .= "<label class='o2DragListLabel'>$label</label>\n";
    $html .= "</td>"   if $useTable;
    $html .= $post unless $useTable;
    my $tdOrSpan = $useTable ? 'td' : 'span';
  }
  $html .= "<$tdOrSpan component=\"DragList\" $attrs></$tdOrSpan>\n";
  $html .= "</$trOrDiv>\n" unless $obj->{parser}->getProperty('manualTrTdTags');
  $html .= "<script type=\"text/javascript\">with(getComponentById('$params{id}')) {";

  # add objects in "items" attribute
  if ($items) {
    $obj->{parser}->parseVars(\$items, 'externalDereference');
    my $items = eval $items;
    die "Didn't understand 'items' attribute: $@" if $@;
    foreach my $item (@{$items}) {
      next unless $item;
      push @{ $obj->{listItems} },  $obj->_object2hash($item);
    }
  }

  my $jsData = $context->getSingleton('O2::Javascript::Data');
  foreach my $item ( @{$obj->{listItems}} ) {
    $html .= "addItem(" . $jsData->dump($item) . ");";
  }
  $html .= "}</script>";
  return $html;
}
#----------------------------------------------------
sub objectItem {
  my ($obj, %params) = @_;
  my ($variableStr, $ignoreError) = $obj->{parser}->matchVariable( $params{content} );
  if ($variableStr) {
    my $object;
    eval {
      $object = $obj->{parser}->findVar($variableStr);
    };
    die $@ if $@ && !$ignoreError;
    return '' unless $object;
    die "Object not a subclass of O2::Obj::Object '$object'" unless $object->isa('O2::Obj::Object');
    my $textMethodName = $obj->{textMethodName};
    $obj->{parser}->parseVars( \$params{name} ) if $params{name} =~ m{ \$ }xms;
    $params{name} ||= scalar $object->$textMethodName() if $textMethodName;
    my %objectHash = %{ $obj->_object2hash($object) };
    foreach my $key (keys %params) {
      $objectHash{$key} = $params{$key};
    }
    push @{ $obj->{listItems} }, \%objectHash;
  }
  return '';
}
#----------------------------------------------------
sub _object2hash {
  my ($obj, $object) = @_;
  my $textMethodName = $obj->{textMethodName} || 'getMetaName';
  return {
    value     => $object->getId(),
    id        => $object->getId(),
    name      => scalar $object->$textMethodName(),
    className => $object->getMetaClassName(),
    parentId  => $object->getMetaParentId(),
    iconUrl   => $object->getIconUrl( $obj->{iconSize} ),
  };
}
#----------------------------------------------------
1;
