package O2CMS::Obj::Feed::Weather::Yr;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);
use O2CMS::Obj::Feed::Weather::Yr::Time;
use Encode qw(from_to);

#----------------------------------------------------------------------
sub getCountry {
  my ($obj) = @_;
  return $obj->_getPlds()->{location}->{country};
}
#----------------------------------------------------------------------
sub getLocationName {
  my ($obj) = @_;
  return $obj->_getPlds()->{location}->{name};
}
#----------------------------------------------------------------------
sub getLatitude {
  my ($obj) = @_;
  return $obj->_getPlds()->{location}->{location}->{latitude};
}
#----------------------------------------------------------------------
sub getLongitude {
  my ($obj) = @_;
  return $obj->_getPlds()->{location}->{location}->{longitude};
}
#----------------------------------------------------------------------
sub getShortTermForecast {
  my ($obj) = @_;
  return ( $obj->_getTimes() )[0]->{body};
}
#----------------------------------------------------------------------
sub getShortTermForecastTitle {
  my ($obj) = @_;
  return ( $obj->_getTimes() )[0]->{title};
}
#----------------------------------------------------------------------
sub getLongTermForecast {
  my ($obj) = @_;
  return ( $obj->_getTimes() )[1]->{body};
}
#----------------------------------------------------------------------
sub getLongTermForecastTitle {
  my ($obj) = @_;
  return ( $obj->_getTimes() )[1]->{title};
}
#----------------------------------------------------------------------
sub _getTimes {
  my ($obj) = @_;
  my $times = $obj->_getPlds()->{forecast}->{text}->{location}->{time};
  return sort { $a->{to} cmp $b->{to} } @{$times};
}
#----------------------------------------------------------------------
sub getLastUpdateTime {
  my ($obj) = @_;
  return $obj->_toTime( $obj->_getPlds()->{meta}->{lastupdate} );
}
#----------------------------------------------------------------------
sub getNextUpdateTime {
  my ($obj) = @_;
  return $obj->_toTime( $obj->_getPlds()->{meta}->{nextupdate} );
}
#----------------------------------------------------------------------
sub getOverviewUrl {
  my ($obj) = @_;
  return $obj->_getPlds()->{links}->{link}->{overview}->{url};
}
#----------------------------------------------------------------------
sub getTabular {
  my ($obj) = @_;
  return map  { O2CMS::Obj::Feed::Weather::Yr::Time->new( time => $_, yrWeather => $obj ) }  @{ $obj->_getPlds()->{forecast}->{tabular}->{time} };
}
#----------------------------------------------------------------------
# return whole XML tree
sub _getPlds {
  my ($obj) = @_;
  $obj->refresh() unless $obj->{plds};
  return $obj->{plds};
}
#----------------------------------------------------------------------
sub refresh {
  my ($obj) = @_;
  $obj->{status} = $obj->_refresh();
}
#----------------------------------------------------------------------
sub _refresh {
  my ($obj) = @_;
  
  # do we have a still fresh cache entry?
  my $cacher = $context->getMemcached();
  my $cacheKey = $obj->getId() . '_' . $obj->getCurrentLocale(); # different data for different locale
  if ($obj->getId()) {
    my $plds = $cacher->get($cacheKey);
    if ( $plds  &&  $obj->_toTime( $plds->{meta}->{nextupdate} ) > time ) {
      $obj->{plds} = $plds;
      return 'ok';
    }
  }
  
  # download xml
  require LWP::Simple;
  my $xml = LWP::Simple::get( $obj->getLocalizedUrl() );
  return 'errorDownloading' unless $xml;
  
  $xml = Encode::decode('iso-8859-1', $xml);
  
  # parse xml
  require XML::Simple;
  my $plds = XML::Simple::XMLin($xml);
  return 'errorParsing' unless $plds;
  
  $obj->{plds} = $plds;
  
  # store plds in cache. Invalidate cache when next update is scheduled
  if ($obj->getId()) {
    my $ttl = $obj->_toTime( $plds->{meta}->{nextupdate} ) - time;
    $cacher->set($cacheKey, $plds, $ttl);
  }

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
# choose feed url based on locale
sub getLocalizedUrl {
  my ($obj) = @_;
  
  my $code = $context->getLocaleCode();
  my $dir = 'place';
  $dir = 'sted' if $code eq 'nb_NO';
  $dir = 'stad' if $code eq 'nn_NO';
  
  my $url = $obj->getUrl();
  return unless $url;
  $url =~ s|(http://[^/]+/)[^/]+|$1$dir|; # first directory decides language
  return $url;
}
#----------------------------------------------------------------------
sub _toTime {
  my ($obj, $timeString) = @_;
  return $context->getSingleton('O2::Util::DateCalc')->dateTime2Epoch($timeString);
}
#----------------------------------------------------------------------
1;
