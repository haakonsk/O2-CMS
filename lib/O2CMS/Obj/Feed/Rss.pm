package O2CMS::Obj::Feed::Rss;

# wrapper for the XML::RSS module

use strict;

use base 'O2::Obj::Object';

#----------------------------------------------------------------------
sub getChannelTitle {
  my ($obj) = @_;
  return $obj->getRss()->channel()->{title};
}
#----------------------------------------------------------------------
sub getChannelLink {
  my ($obj) = @_;
  return $obj->getRss()->channel()->{link};
}
#----------------------------------------------------------------------
sub getChannelDescription {
  my ($obj) = @_;
  return $obj->getRss()->channel()->{description};
}
#----------------------------------------------------------------------
sub hasImage {
  my ($obj) = @_;
  return $obj->getRss()->image() ? 1 : 0;
}
#----------------------------------------------------------------------
sub getImageTitle {
  my ($obj) = @_;
  return $obj->getRss()->image()->{title};
}
#----------------------------------------------------------------------
sub getImageUrl {
  my ($obj) = @_;
  return $obj->getRss()->image()->{url};
}
#----------------------------------------------------------------------
sub getImageLink {
  my ($obj) = @_;
  return $obj->getRss()->image()->{link};
}
#----------------------------------------------------------------------
sub getItems {
  my ($obj) = @_;
  my $rss = $obj->getRss();
  require O2CMS::Obj::Feed::Rss::Item;
  return map  { O2CMS::Obj::Feed::Rss::Item->new(%$_) }  @{ $rss->{items} } if $rss->{items};
}
#----------------------------------------------------------------------
# return whole XML::RSS object
sub getRss {
  my ($obj) = @_;
  $obj->refresh() unless $obj->{rss};
  die "Couldn't get rss, status: $obj->{status}" unless $obj->{rss};
  return $obj->{rss};
}
#----------------------------------------------------------------------
sub refresh {
  my ($obj) = @_;
  $obj->{status} = $obj->_refresh();
}
#----------------------------------------------------------------------
# download and parse rss. return status code
sub _refresh {
  my ($obj) = @_;

  # download xml
  require LWP::Simple;
  my $xml = LWP::Simple::get( $obj->getUrl() );
  return 'errorDownloading' unless $xml;
  
  # parse rss
  require XML::RSS;
  my $rss = XML::RSS->new();
  eval {
    $rss->parse($xml);
  };
  my $errorMsg = $@;
  warn "Rss parsing error: $errorMsg" if $errorMsg;
  return 'errorParsing' if $errorMsg || !$rss->channel()->{title};
  
  $obj->{rss} = $rss;
  return 'ok';
}
#----------------------------------------------------------------------
# errorDownloading, errorParsing, ok
sub getStatus {
  my ($obj) = @_;
  $obj->refresh() unless $obj->{rss};
  return $obj->{status};
}
#----------------------------------------------------------------------
1;
