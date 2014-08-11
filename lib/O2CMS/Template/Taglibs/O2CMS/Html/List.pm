package O2CMS::Template::Taglibs::O2CMS::Html::List;

# Interface for the generic javascript list component.
#
# Most important attributes:
# id - componentId of our list. Also used as prefix for input fields.
# type - what javascript class we want to use (default TableList)
# items - items to populate list with. Perl arrayref of O2 objects, hashes or plain strings.
# selectedValues - perl arrayref of values that should be pre-selected
# extraItemFields - extra fields to include from objects.
#                   If extraItemFields="price,description", then getPrice() and getDescription
#                   are called on all objects given in "items" attribute. Each item in the list
#                   will end up with "price" and "description" fields.
# submitType - this list should be submitted when form submits.
#               Value "all" submits info about all items, "selected" will limit to those selected.
# submitItemFields - describes what item fields to submit. Default is "value".
#                    If it contains one field, an array-of-strings structure will be submitted. More than one
#                    will result in a array-of-hashes structure.
#
# Examples:
# <o2 list id="offer.documentIds"
#  items="$allDocuments" selectedValues="[$offer->getDocumentIds()]" extraItemFields="byteSize"
#  submitType="selected" submitItemFields="id"
# />
#
#

use strict;

use base 'O2::Template::Taglibs::Html';

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    list     => 'postfix',
    listItem => '',
  );
  $obj->{errors} = [];
  return ($obj, %methods);
}
#----------------------------------------------------
# <o2 list id="myId" type="TableList"> + a lot more. Will write a tutorial on this vonheim@20060309
sub list {
  my ($obj, %params) = @_;
  $obj->addJsFile(file => 'componentBase');
  $params{type} ||= 'TableList';
  $obj->addJsFile(file => $params{type});
  $obj->{parser}->parseVars( \$params{id} );
  $obj->{listItems} = [];
  my $extraItemFields = substr ($params{extraItemFields}, 0, 1) eq '$'  ?  $obj->{parser}->findVar( $params{extraItemFields} )  :  $params{extraItemFields};
  $obj->{extraItemFields} = [ split /\s*,\s*/, $extraItemFields ];
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();

  $obj->{parser}->_parse( \$params{content} );
  delete $params{content};
  $params{class} ||= 'list';
  my $attrs = join ' ', map "$_=\"$params{$_}\"", keys %params;
  my $html = "<div component=\"$params{type}\" $attrs></div>";
  $html   .= "<div id=\"$params{id}_submitInputFields\"></div>";
  $html   .= "<script type=\"text/javascript\">with(getComponentById('$params{id}')) {";

  $obj->{parser}->parseVars( \$params{headers} );
  if ($params{headers}) {
    my $headers = substr ($params{headers}, 0, 1) eq '$'  ?  $obj->{parser}->findVar( $params{headers} )  :  $params{headers};
    $html .= 'setHeaders([' . join (',', map { "'$_'" } split (',', $headers)) . ']);';
  }

  # add objects in "items" attribute
  if( $params{items} ) {
    $obj->{parser}->parseVars(\$params{items}, 'externalDereference');
    my $items = eval $params{items} || [];
    die "Error with items attribute: $@" if $@;
    die "Items attribute does not contain a perl arrayref: $params{items} (items after eval: $items)" if ref $items ne 'ARRAY';
    foreach my $item (@$items) {
      my %item = $obj->_item2hash($item);
      die $@ if $@;
      push @{ $obj->{listItems} }, \%item;
    }
    delete $params{items};
  }

  # select items
  if( $params{selectedValues} ) {
    $obj->{parser}->parseVars(\$params{selectedValues}, 'externalDereference');
    my $selectedValues = eval $params{selectedValues} || [];
    die "Error with selectedValues attribute: $@" if $@;
    die "selectedValues attribute does not contain a perl arrayref: $params{selectedValues}" if ref $selectedValues ne 'ARRAY';
    my %selectedValues = map { $_ => 1 } @{$selectedValues};
    foreach my $item (@{ $obj->{listItems} }) {
      $item->{selected} = 1 if $selectedValues{ $item->{value} };
    }
  }

  $html .= "setItems(" . $jsData->dump( $obj->{listItems} ) . ");\n";
  $html .= "}\n";
  # trigger generation of input fields on submit
  if ( $params{submitType} && $params{submitType} ne 'none') { 
    my $formName = $obj->{parser}->getProperty('currentFormName');
    $html .= "o2.rules.addOnSubmitEval('$formName', \"getComponentById('$params{id}').onSubmit()\");\n";
  }

  $html .= "</script>\n";
  return $html;
}
#----------------------------------------------------
sub listItem {
    my ($obj, %params) = @_;
    $obj->{parser}->_parse(\$params{content});
    my $name = delete $params{content};
    $params{name} = $name if $name;
    $params{value} = $name unless exists $params{value};
    push @{$obj->{listItems}}, {%params};
    return '';
}
#----------------------------------------------------
# Convert item element to a hash. An item may be a hash, string or O2 object.
# Objects will be converted into a hash of standard properties. Extra properties may be added via extraItemFields attribute in <o2 list>.
sub _item2hash {
  my ($obj, $item) = @_;
  return (value => $item) unless ref $item;
  return %{$item}             if ref $item eq 'HASH';
  my %hash = (
    value     => $item->getId(),
    id        => $item->getId(),
    name      => $item->getMetaName(),
    className => $item->getMetaClassName(),
    parentId  => $item->getMetaParentId(),
  );
  my @extraItemFields = @{ $obj->{extraItemFields} };
  foreach my $field (@extraItemFields) {
    my ($fieldName, $dataType) = $field =~ /^(\w+):?(string|hash|array)?$/;
    if (!$fieldName) {
      $@ = "extraItemField '$field' has illegal format";
      return;
    }
    eval {
      my $method = $item->can($fieldName) ? $fieldName : 'get' . ucfirst $fieldName;
      my @result = $item->$method();
      if ($dataType eq 'array') {
        $obj->{extraItemFields} = [];
        @result = map  { (ref $_) =~ /\:\:Obj\:\:/ ? { $obj->_item2hash($_) } : $_ }  @result;
        $obj->{extraItemFields} = \@extraItemFields;
        $hash{$fieldName} = \@result;
      }
      elsif ($dataType eq 'hash') {
        $hash{$fieldName} = {@result};
      }
      else {
        $hash{$fieldName} = $result[0];
      }
    };
    return if $@;
  }
  return %hash;
}
#----------------------------------------------------
1;
