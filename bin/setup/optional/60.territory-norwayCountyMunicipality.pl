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


importCounties();
importMunicipalities();


sub importCounties {
  my $csvPath = "$ENV{O2ROOT}/bin/setup/optional/data/norway-counties.csv";
  open(F, '<:encoding(latin1)', $csvPath) or die "$csvPath: $!";
  my $csvText = join '', <F>;
  close(F);

  my $exporter = O2::Util::Exporter->new();
  my $rows = $exporter->parse(format=>'CSV', csvDelimiter=>';', data=>\$csvText);

  my $countyMgr = O2CMS::Mgr::Territory::CountyManager->new(context=>$context);
  foreach my $row (@$rows) {
    my ($code,$name) = @$row;

    my $county = $norway->addOrUpdateChild(
      metaName  => $name,
      code      => $code,
      className => 'O2CMS::Obj::Territory::County',
      );
    _debug($county);
    $county->save();
  }
}



sub importMunicipalities {
  my $postalDataUrl = 'http://epab.posten.no/Norsk/Nedlasting/_Files/PostNrSS.txt';
  my $postalData = get($postalDataUrl);
  die "Could not download postal data from '$postalDataUrl'" unless $postalData;
  $postalData = decode('ISO8859-1', $postalData);

  my %seenMunicipality = ();
  my @rows = _naiveCsvParser($postalData);
  foreach my $row (@rows) {
    my ($municipalityNumber,$municipalityName) = @$row[-2,-1];
    next if $seenMunicipality{$municipalityNumber}++ > 0; # list of postal places repeats municipalitites. process each municipality only once
    die "municipalityNumber '$municipalityNumber' malformed" unless $municipalityNumber =~ /^\d{4}$/;
    die "municipalityName '$municipalityName' malformed"     unless $municipalityName   =~ /\w+/;
    my ($countyNumber) = $municipalityNumber =~ /^(\d\d)/; # two first digits of municipality number is county number

    my $county = $norway->getChildByCodeAndClassName("NO-$countyNumber", 'O2CMS::Obj::Territory::County');
    die "County '$countyNumber' not found" unless $county;
    
    my $municipality = $county->addOrUpdateChild(
      metaName  => $municipalityName,
      code      => $municipalityNumber,
      className => 'O2CMS::Obj::Territory::Municipality'
      );
    _debug($municipality);
    $municipality->save();
  }
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
