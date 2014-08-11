package O2CMS::Frontend::Gui::Search::Search;

use strict;

use base 'O2::Gui';

use O2 qw($context $config);

#----------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->search();
}
#----------------------------------------------------------------------------
sub getSearchResults {
  my ($obj, $skip, $limit) = @_;

  my $query = $obj->getParam('query');
  $query  =~ s{ \A [*] \z }{}xms;
  $query .=  '*'  if  $query =~ m{ \A [a-zA-Z0-9æøåÆØÅ]+ \z }xms  &&  $config->get('o2.search.autoTruncateQueries');
  return () unless $query;

  my $session    = $context->getSession();
  my $searchInfo = $session->get('searchInfo');

  my @objects;
  my %params;
  if ( $obj->getParam('index') ) {
    # If the indexName is provided, use it
    $params{indexName} = $obj->getParam('index');
  }
  elsif ( $config->get('o2.search.searchIndexes') ) {
    # if not, get the indexes from config
    $params{indexNames} = $config->get('o2.search.searchIndexes');
    
    if ( ref $params{indexNames} eq 'HASH' ) {
      # Changed searchIndexes into HASH to be able to link each index to an objectType, ref. ArticleManager
      # The downside is that Search for some reason expected an array.
      # Therefore, create an array of indexNames if the config gives an Hash - look in all?
      my @indexNames;
      foreach my $key (keys %{$params{indexNames}}) {
        push @indexNames, $params{indexNames}->{$key};
      }
      $params{indexNames} = \@indexNames;
    }
  }
  else {
    # if the config is missing and no index has been provided
    # use the o2Generic
    $params{indexName} = 'o2GenericIndex';
  }
  
  if (!$searchInfo  ||  $searchInfo->{query} ne $query  ||  $searchInfo->{validUntil} < time) {
    $searchInfo = {
      query          => $query,
      invalidIndexes => [],
    };
  }
  $searchInfo->{validUntil} = time + 30*60;

  $skip = $obj->_getNumResultsToSkip($skip, $searchInfo) || 0;

  require O2CMS::Search::ObjectQuery;
  my $resultSet = O2CMS::Search::ObjectQuery->new(%params)->search($query);
  my @objectIds = $resultSet->getObjectIds();
  $searchInfo->{numResults} = scalar @objectIds;
  my $i = 0;
  while (($skip+$i < @objectIds  &&  (!$limit  ||  @objects < $limit))) {
    my $objectId = $objectIds[ $skip+$i ];
    my $object = $context->getObjectById($objectId);
    if ($object  &&  $object->isPublishable( $context->getEnv('SCRIPT_URI') )) {
      push @objects, $object;
    }
    else {
      $searchInfo->{invalidIndex}->{ $skip+$i } = 1;
    }
    $i++;
  }
  $searchInfo->{invalidIndexes} = [ keys %{ $searchInfo->{invalidIndex} } ];
  $session->set('searchInfo', $searchInfo);
  return @objects;
}
#----------------------------------------------------------------------------
# Returns the number of results from the most recent search in the same session.
# The number of results returned here may not be 100% accurate, since we don't want
# to instantiate all the objects to see if they're valid result objects.
sub getNumResults {
  my ($obj) = @_;
  my $searchInfo = $context->getSession()->get('searchInfo');
  return $searchInfo  ?  $searchInfo->{numResults} - scalar @{ $searchInfo->{invalidIndexes} }  :  0;
}
#----------------------------------------------------------------------------
sub _getNumResultsToSkip {
  my ($obj, $skip, $searchInfo) = @_;
  $skip ||= 0;
  
  for my $indexToSkip (@{ $searchInfo->{invalidIndexes} }) {
    last if $indexToSkip >= $skip;
    $skip++;
  }
  return $skip;
}
#----------------------------------------------------------------------------
sub search {
  my ($obj) = @_;

  my @objects = $obj->getSearchResults();

  my $treeManager = $context->getSingleton('O2::Mgr::MetaTreeManager');
  my $pathsToObjects = {};
  if ($config->get('o2.search.resolvePathToObjects')) {
    foreach my $object (@objects) {
      my @parents = $treeManager->getObjectPathTo($object);
      for (1..2) {
        shift @parents;
      }
      $pathsToObjects->{ $object->getId() } = [map {$_->getTitle()} @parents];
    }
  }

  my %params = (
    pathsToObjects => $pathsToObjects,
    results        => \@objects,
    numHits        => scalar @objects,
    query          => $obj->getParam('query')      || '',
    pageNumber     => $obj->getParam('pageNumber') || 0,
  );

  return $obj->display("searchPage.html", %params) if $obj->getParam('noPageTemplate');

  my $template = $obj->getParam('template') || 'searchPage';
  $template    =~ s/\W//g;
  $template   .= '.html';

  $obj->displayPage(
    $template,
    %params,
    pageTemplateId   => $obj->getParam('pageTemplateId'),
    pageTemplatePath => $obj->getParam('pageTemplatePath'),
  );
}
#----------------------------------------------------------------------------
1;
