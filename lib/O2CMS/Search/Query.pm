package O2CMS::Search::Query;

use base 'O2CMS::Search::Base';

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = $package->SUPER::new(%params);
  return $obj;
}
#---------------------------------------------------------------------------------------------------------------
sub setRange {
  my ($obj, $start, $end) = @_;
  $obj->{start} = $start;
  $obj->{end}   = $end;
}
#---------------------------------------------------------------------------------------------------------------
sub getRange {
  my ($obj, $start, $end) = @_;
  return $obj->{start}, $obj->{end};
}
#---------------------------------------------------------------------------------------------------------------
sub search {
  my ($obj, $query) = @_;

  my @indexNames;
  my @indexes = ( $obj->getIndexName() || $obj->getIndexNames() );
  foreach my $index (@indexes) {
    my $indexPath = $obj->getIndexesPath() . "/$index.idx";

    if (-e $indexPath) {
      push @indexNames, $indexPath;
    }
    else {
      warn "No index found at '$indexPath'";
    }
  }
  die "No indexes found" unless @indexNames;

  require SWISH::API;
  my $swish = SWISH::API->new(join ' ', @indexNames);
  if ( $swish->Error() ) {
    die 'Error in searchengine: ' . $swish->ErrorString() . ' ' . $swish->LastErrorMsg() . ' used index(s):' . join ' ', @indexNames;
  }

  # I think Swish requires iso-8859-1.
  require Encode;
  $query = Encode::encode('iso-8859-1', $query);
  
  my $swishResults = $swish->Query($query);

  # Added by thomasez 2008-04-09, This may have a side effect but it is to get
  # rid of the "No search words specified" error message from SWISH-E
  # $query comes ad "()" so we'll check for any characters.
  if ( $swish->Error() && $query =~ /\w/ ) {
    die "Error in searchengine: " . $swish->ErrorString() . ' ' . $swish->LastErrorMsg() . " used index(s):" . join ' ', @indexNames if $swish->CriticalError();
    eval { # Want the line where the error occurred (the next line), so dying instead of printing. But we don't really want to die, so we catch it and print....
      die "<span style='color: red'>" . $swish->ErrorString() . ' ' . $swish->LastErrorMsg() . '</span>';
    };
    print $@;
  }
  my ($start, $end) = $obj->getRange();
  my $resultsClassName = $obj->_getResultsClassName();
  my $results = $resultsClassName->new(
    results => $swishResults,
    start   => $start,
    end     => $end,
  );

  return $results;
}
#---------------------------------------------------------------------------------------------------------------
sub _getResultsClassName {
  return 'O2CMS::Search::Results';
}
#---------------------------------------------------------------------------------------------------------------
package O2CMS::Search::Results; # Class representing a set of results

use strict;

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  die "No results-object supplied" unless ref $params{results};
  
  my $obj = bless \%params, $pkg;
  $obj->{results}->SeekResult( $obj->{start} ) if defined $obj->{start} && $obj->{start} > 0;
  return $obj;
}
#---------------------------------------------------------------------------------------------------------------
sub getNumHits {
  my ($obj) = @_;
  return $obj->{results}->Hits();
}
#---------------------------------------------------------------------------------------------------------------
sub getNextResult {
  my ($obj) = @_;
  my $result = $obj->{results}->NextResult();
  return unless $result;
  return O2CMS::Search::Result->new( result => $result );
}
#---------------------------------------------------------------------------------------------------------------
sub getAllResults {
  my ($obj) = @_;
  my @results;
  my $maxNumResults;
  $maxNumResults = $obj->{end} - $obj->{start} if $obj->{end};
  $obj->{results}->SeekResult( $obj->{start} || 0 );
  my $numResults = 0;
  while ( my $result = $obj->{results}->NextResult() ) {
    push @results, O2CMS::Search::Result->new(result => $result);
    last if $maxNumResults && ++$numResults >= $maxNumResults;
  }
  return @results;
}
#---------------------------------------------------------------------------------------------------------------
package O2CMS::Search::Result; # Class representing a single result

use strict;

use O2 qw($context);

#---------------------------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  die "No result supplied" unless ref $params{result};
  return bless \%params, $pkg;
}
#---------------------------------------------------------------------------------------------------------------
sub getId {
  my ($obj) = @_;
  my $filePath = $obj->{result}->Property('swishdocpath');
  my ($id) = $filePath =~ m{ ([^/\\]+) \z }xms or die "Could not find ID from filePath '$filePath'";
  $id      =~ s/\_([\da-fA-F][\da-fA-F])/pack('C', hex $1)/ge;
  $id      =~ s{ [.] (?: xml | plds | html ) \z }{}xms;
  die "ID ($id) isn't numeric" if $id !~ m{ \A \d+ \z }xms;
  return $id;
}
#---------------------------------------------------------------------------------------------------------------
sub getRank {
  my ($obj) = @_;
  return $obj->{result}->Property('swishrank');
}
#---------------------------------------------------------------------------------------------------------------
sub getTimeStamp {
  my ($obj) = @_;
  $obj->{result}->Property('swishlastmodified');
}
#---------------------------------------------------------------------------------------------------------------
sub getXML {
  my ($obj) = @_;
  my $filePath = $obj->{result}->Property('swishdocpath');
  return $context->getSingleton('O2::File')->getFile($filePath);
}
#---------------------------------------------------------------------------------------------------------------
sub getContent {
  my ($obj) = @_;
  my $xml = $obj->getXML();
  $xml    =~ s/<\?[^>]+\?>\n//;
  $xml    =~ s/<\/?document>\n?//g;
  $xml    =~ s/^\s\s//mg;
  return $xml;
}
#---------------------------------------------------------------------------------------------------------------
sub getPLDS {
  my ($obj) = @_;
  my $filePath = $obj->{result}->Property('swishdocpath');
  $filePath    =~ s/\.xml$/.plds/;
  return $context->getSingleton('O2::Data')->load($filePath);
}
#---------------------------------------------------------------------------------------------------------------
1;
