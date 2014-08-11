#!/usr/bin/perl

use strict;
use O2::Context;
use O2CMS::Mgr::Territory::CountryManager;
use O2CMS::Mgr::Territory::MunicipalityManager;
use O2::Util::Exporter;
use LWP::Simple;
use Encode;

my $context = O2::Context->new();
my $countryMgr = O2CMS::Mgr::Territory::CountryManager->new(context=>$context);
my $municipalityMgr = O2CMS::Mgr::Territory::MunicipalityManager->new(context=>$context);
my $norway = $countryMgr->getCountryByCode('NO');
die "Can't find country object for norway" unless $norway;

my $url = 'http://fil.nrk.no/yr/viktigestader/noreg.txt';
print "Downloading $url...\n";
my $csvText = get($url);
die "Could not download $url" unless $csvText;
$csvText = decode('utf8', $csvText);
$csvText =~ s/^\W+//;


my $exporter = O2::Util::Exporter->new();
my $rows = $exporter->parse(format=>'CSV', csvDelimiter=>"\t", data=>\$csvText, csvIncludeHeader=>1);

foreach my $row (@$rows) {
  next if $row->{Prioritet}==99; # ignore most of the 
  my $municipalCode = sprintf('%.4d', $row->{Kommunenummer});
  # Jan Mayen and Svalbard are not part of the official norwegian county structure,
  # so they do not fit into the current tree structure. Ref: http://no.wikipedia.org/wiki/Fylke_(Norge)
  next if $municipalCode==2100 || $municipalCode==2200;
  next unless $row->{Nynorsk} =~ /^http/i; # ignore malformed urls (5 contained "#N/A" when this was written)
  
  
  my ($municipality) = $norway->queryChildren(classNames=>['O2CMS::Obj::Territory::Municipality'], code=>$municipalCode);
  die "CSV refers to a municipality not present in database (code '$municipalCode')" unless $municipality;
  
  my $yrPlace = $municipality->addOrUpdateChild(metaName=>$row->{Stadnamn}, code=>$row->{Lat}.','.$row->{Lon}, className=>'O2CMS::Obj::Territory::YrPlace');
  $yrPlace->setLatitude($row->{Lat});
  $yrPlace->setLongitude($row->{Lon});
  $yrPlace->setXmlUrl($row->{Nynorsk});
  print encode('utf8', ($yrPlace->getId()?'Update':'Insert') .' '. $yrPlace->getType().' '.$yrPlace->getName()."\n");
  $yrPlace->save();
}
