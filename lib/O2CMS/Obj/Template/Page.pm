package O2CMS::Obj::Template::Page;

use strict;

use base 'O2CMS::Obj::Template::Grid';
use base 'O2CMS::Role::Obj::Page';

#-------------------------------------------------------------------------------
sub setKeywords {
  my ($obj, $keywords) = @_;
  $obj->{keywords} = $keywords;
}
#-------------------------------------------------------------------------------
sub getKeywords {
  my ($obj) = @_;
  return $obj->{keywords} || [];
}
#-------------------------------------------------------------------------------
sub getUrl {
  return '';
}
#-------------------------------------------------------------------------------
sub getContentPlds {
  my ($obj) = @_;
  my $data = $obj->SUPER::getContentPlds();
  $data->{title}    = $obj->{title};
  $data->{keywords} = $obj->{keywords};
  return $data;
}
#-------------------------------------------------------------------------------
sub setContentPlds {
  my ($obj, $plds) = @_;
    
  if ($obj->verifyContentPlds($plds)) {
    $obj->{title}    = delete $plds->{title};
    $obj->{keywords} = delete $plds->{keywords};
    return $obj->SUPER::setContentPlds($plds);
  }
  else {
    die "ContentPLDS could not be verified: $@";
  }
}
#-------------------------------------------------------------------------------
1;
