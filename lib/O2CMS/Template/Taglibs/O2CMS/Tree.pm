package O2CMS::Template::Taglibs::O2CMS::Tree;

# Tree access - very unfinished

use strict;

use base 'O2::Template::Taglibs::Html';

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    listFolder   => 'postfix',
    chooseFolder => 'postfix',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub chooseFolder {
  my ($obj, %params) = @_;
  return "Missing onObjectChangeMethod attribute in chooseFolder tag" unless $params{onObjectChangeMethod};

  $params{componentId} = delete $params{id} || 'chooseFolder';

  my $path = $obj->_getThisPath()."/HTML/chooseFolder.html";
  my $html = '';
  {
    local $/ = undef;
    open (FH, $path) or die "Could not open file '$path': $!";
    $html = <FH>;
    close (FH);
  }

  $params{height} ||= 142;

  foreach (qw/folderId componentId onObjectChangeMethod viewMode height/) {
    my $value = $params{$_};
    $value    = $obj->{parser}->findVar($value) if $value =~ m{ \A \$ }xms;
    $obj->{parser}->setVar($_ => $value);
  }
  $obj->{parser}->_parse(\$html);
  return $html;
}
#----------------------------------------------------
sub _getThisPath {
  my ($obj) = @_;
  my $module = ref $obj;
  $module =~ s{ :: }{/}xmsg;
  my $filePath = $INC{"$module.pm"};
  $filePath    =~ s{ [.]pm \z }{}xms;
  return $filePath;
}
#----------------------------------------------------
1;
