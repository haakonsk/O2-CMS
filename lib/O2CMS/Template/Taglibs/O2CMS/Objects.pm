package O2CMS::Template::Taglibs::O2CMS::Objects;

use strict;

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    objectComponent => 'postfix',
    objectHash      => 'postfix', # returns javascript hash based on a O2 object
  );
  return ($obj, %methods);
}
#----------------------------------------------------
# convert o2 object to javascript datastructure
sub objectHash {
  my ($obj, %params) = @_;

  my $object = $obj->{parser}->findVar( $params{content} );

  my %attribs;
  my @extraFields = split /\s*,\s*/, $params{extraFields};
  foreach my $field (@extraFields) {
    my ($fieldName, $dataType) = $field =~ /^(\w+):?(scalar|hash|array)?$/;
    return "extraItemField '$field' has illegal format" unless $fieldName;
    $attribs{$fieldName} = $dataType || 'scalar';
  }

  require O2::Util::AccessorMapper;
  my $accessorMapper = O2::Util::AccessorMapper->new();
  my %hash = $accessorMapper->objectToHash($object, %attribs);
  $hash{iconUrl} = $object->getIconUrl();
  require O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  return $jsData->dump(\%hash);
}
#----------------------------------------------------
1;
