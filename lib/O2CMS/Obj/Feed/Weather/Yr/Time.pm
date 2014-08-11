package O2CMS::Obj::Feed::Weather::Yr::Time;

use strict;

use O2 qw($config);

#---------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless \%init, $pkg;
}
#---------------------------------------------------------------------
sub getFromTime {
  my ($obj) = @_;
  return $obj->{yrWeather}->_toTime( $obj->{time}->{from} );
}
#---------------------------------------------------------------------
sub getToTime {
  my ($obj) = @_;
  return $obj->{yrWeather}->_toTime( $obj->{time}->{to} );
}
#---------------------------------------------------------------------
sub getSymbolUrl {
  my ($obj) = @_;
  return $config->get( 'frontend.yr.symbols.' . $obj->getSymbolNumber() );
}
#---------------------------------------------------------------------
sub getSymbolNumber {
  my ($obj) = @_;
  return $obj->{time}->{symbol}->{number};
}
#---------------------------------------------------------------------
sub getSymbolName {
  my ($obj) = @_;
  return $obj->{time}->{symbol}->{name};
}
#---------------------------------------------------------------------
sub getPrecipitation {
  my ($obj) = @_;
  return $obj->{time}->{precipitation}->{value};
}
#---------------------------------------------------------------------
sub getWindDirection {
  my ($obj) = @_;
  return $obj->{time}->{windDirection}->{name};
}
#---------------------------------------------------------------------
sub getWindDirectionCode {
  my ($obj) = @_;
  return $obj->{time}->{windDirection}->{code};
}
#---------------------------------------------------------------------
sub getWindDirectionDegrees {
  my ($obj) = @_;
  return $obj->{time}->{windDirection}->{deg};
}
#---------------------------------------------------------------------
sub getWindSpeedName {
  my ($obj) = @_;
  return $obj->{time}->{windSpeed}->{name};
}
#---------------------------------------------------------------------
sub getWindSpeed {
  my ($obj) = @_;
  return $obj->{time}->{windSpeed}->{mps};
}
#---------------------------------------------------------------------
sub getTemperature {
  my ($obj) = @_;
  return $obj->{time}->{temperature}->{value};
}
#---------------------------------------------------------------------
sub getTemperatureUnit {
  my ($obj) = @_;
  return $obj->{time}->{temperature}->{unit};
}
#---------------------------------------------------------------------
sub getPressure {
  my ($obj) = @_;
  return $obj->{time}->{pressure}->{value};
}
#---------------------------------------------------------------------
sub getPressureUnit {
  my ($obj) = @_;
  return $obj->{time}->{pressure}->{unit};
}
#---------------------------------------------------------------------
1;

__END__
<time from="2008-10-30T18:00:00" to="2008-10-31T00:00:00" period="3">
  <!-- Valid from 2008-10-30T18:00:00 to 2008-10-31T00:00:00 -->
  <symbol number="4" name="Cloudy" />
  <precipitation value="0.0" />
  <!-- Valid at 2008-10-30T18:00:00 -->
  <windDirection deg="33.9" code="NE" name="Northeast" />
  <windSpeed mps="4.8" name="Gentle breeze" />
  <temperature unit="celcius" value="0" />
  <pressure unit="hPa" value="1006.8" />
</time>
