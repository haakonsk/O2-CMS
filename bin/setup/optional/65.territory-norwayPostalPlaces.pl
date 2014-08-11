#!/usr/bin/perl

use strict;
use O2::Context;
use O2CMS::Mgr::Territory::CountryManager;
use O2CMS::Mgr::Territory::CountyManager;
use O2CMS::Mgr::Territory::MunicipalityManager;
use O2CMS::Mgr::Territory::PostalPlaceManager;
use O2::Util::Exporter;
use LWP::Simple;
use Encode;

my $context = O2::Context->new();
my $countryMgr = O2CMS::Mgr::Territory::CountryManager->new(context=>$context);
my $norway = $countryMgr->getCountryByCode('NO');
die "Can't find country object for norway" unless $norway;


my $postalDataUrl = 'http://epab.posten.no/Norsk/Nedlasting/_Files/PostNrSS.txt';
my $postalData = get($postalDataUrl);
die "Could not download postal data from '$postalDataUrl'" unless $postalData;
$postalData = decode('ISO8859-1', $postalData);

my %seenPostalPlaces = ();
my @rows = _naiveCsvParser($postalData);
foreach my $row (@rows) {
  my ($municipalityNumber,$municipalityName) = @$row[-2,-1];
  die "municipalityNumber '$municipalityNumber' malformed" unless $municipalityNumber =~ /^\d{4}$/;
  die "municipalityName '$municipalityName' malformed"     unless $municipalityName   =~ /\w+/;
  my ($countyNumber) = $municipalityNumber =~ /^(\d\d)/; # two first digits of municipality number is county number
  die "County number not found in '$municipalityNumber'" unless $countyNumber;

  my ($postalCode, $postalName) = @$row[0,1];
  die "Postal code '$postalCode' malformed"  unless $postalCode =~ /^\d{4}$/;
  die "Postal place '$postalName' malformed" unless $postalCode =~ /\w/;
  next if $seenPostalPlaces{$postalCode}++ > 0;
  
  
  my ($municipality) = $norway->queryChildren(classNames=>['O2CMS::Obj::Territory::Municipality'], code=>$municipalityNumber);
  die "Unknown municipality $municipalityName (code: $municipalityNumber)" unless $municipality;

  my $postalPlace = $municipality->addOrUpdateChild(
    metaName  => _ucFirstWords($postalName),
    code      => $postalCode,
    className => 'O2CMS::Obj::Territory::PostalPlace'
    );
  _debug($postalPlace);
  $postalPlace->save();
}



# uppercase first letter in each word, lowercase all other
sub _ucFirstWords {
  my ($string) = @_;
  $string =~ s/\b(\S)(\S+)/\u$1\L$2\E/g;
  return $string;
}


# XXX rip this out when we have fixed O2::Util::Exporter::CSV
# (currently uses over an hour parsing 2.5mb of data on my machine)
sub _naiveCsvParser {
  my ($csv) = @_;
  my @rows = ();
  foreach my $row ( split(/\n/, $csv) ) {
    push @rows, [ $row =~ /\"([^\"]*)\"/g ];
  }
  return @rows;
}


sub _debug {
  my ($territory) = @_;
  print encode('utf8', ($territory->getId()?'Update':'Insert') .' '. $territory->getType().' '.$territory->getName()."\n");
}
