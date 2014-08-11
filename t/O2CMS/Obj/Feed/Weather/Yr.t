use strict;

use Test::More qw(no_plan);
BEGIN {
  $ENV{O2CONF} = "$ENV{O2ROOT}/t/O2-Obj-Feed-Weather-Yr/conf"; # need to make sure en_US, nb_NO and nn_NO are legal locales
}

use O2 qw($context);

my %locales = (
  'en_US' => {url=>'http://www.yr.no/place/Norway/Møre_og_Romsdal/Ørsta/Ørsta~175981/forecast.xml', country=>'Norway'},
  'nb_NO' => {url=>'http://www.yr.no/sted/Norge/Møre_og_Romsdal/Ørsta/Ørsta~175981/varsel.xml',     country=>'Norge'},
  'nn_NO' => {url=>'http://www.yr.no/stad/Noreg/Møre_og_Romsdal/Ørsta/Ørsta~175981/varsel.xml',     country=>'Noreg'},
);

my $yrFeedMgr = $context->getSingleton('O2CMS::Mgr::Feed::Weather::YrManager');

my $yr = $yrFeedMgr->newObject();
$yr->setMetaName('Yr test feed');

# set url for all locales, and make sure we are able to parse each one
foreach my $locale (keys %locales) {
  $context->setLocaleCode($locale);
  $yr->setUrl($locales{$locale}->{url});

  $yr->refresh();
  is( $yr->getStatus(), 'ok',                          'getStatus()');
  ok( $yr->getLocationName(),                          'getLocationName()');
  is( $yr->getCountry(), $locales{$locale}->{country}, 'getCountry()');
  ok( $yr->getLastUpdateTime()<=time(),                'getLastUpdateTime()');
  ok( $yr->getNextUpdateTime()>=time(),                'getNextUpdateTime()');
  ok( $yr->getLatitude()>0,                            'getLatitude()');
  ok( $yr->getLongitude()>0,                           'getLongitude()');
  
  my @tabular = $yr->getTabular();
  ok( @tabular>0 ,'getTabular()');
  my ($time) = $tabular[0];
  ok( $time->getFromTime()>0,  'getFromTime()' );
  ok( $time->getToTime()>0,    'getToTime()'   );
  ok( $time->getSymbolUrl(), 'getSymbolUrl()');
  ok( $time->getSymbolNumber(), 'getSymbolNumber()');
  ok( $time->getSymbolName(), 'getSymbolName()');
  ok( defined $time->getPrecipitation(), 'getPrecipitation()');
  ok( $time->getWindDirection(), 'getWindDirection');
  ok( $time->getWindDirectionCode(), 'getWindDirectionCode()');
  ok( defined $time->getWindDirectionDegrees(), 'getWindDirectionDegrees()');
  ok( $time->getWindSpeedName(), 'getWindSpeedName()');
  ok( defined $time->getWindSpeed(), 'getWindSpeed()');
  ok( defined $time->getTemperature(), 'getTemperature()');
  ok( $time->getTemperatureUnit(), 'getTemperatureUnit()');
  ok( $time->getPressure(), 'getPressure()');
  ok( $time->getPressureUnit(), 'getPressureUnit()');
}
$yr->save();
ok($yr->getId() > 0, 'Object saved ok');

my $yrFromDb = $context->getObjectById( $yr->getId() );
ok($yrFromDb, 'getObjectById()');
# are urls loaded ok
foreach my $locale (keys %locales) {
  $context->setLocaleCode($locale);
  is($yrFromDb->getUrl(), $yr->getUrl(), "getUrl() for $locale");
}

END {
  $yr->deletePermanently();
}
