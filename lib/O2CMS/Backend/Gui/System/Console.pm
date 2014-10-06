package O2CMS::Backend::Gui::System::Console;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $db);

#------------------------------------------------------------------
sub init { 
  my ($obj) = @_;
  my ($query, $placeHolders) = $obj->_buildQuery('select count(*)');
  $obj->display(
    'showConsole.html',
    gui             => $obj,
    totalNumResults => $db->fetch($query, @{$placeHolders}),
  );
}
#------------------------------------------------------------------
sub _buildQuery {
  my ($obj, $startOfQuery) = @_;
  my $fromDate =       $obj->getParam( 'fromDate' );
  $fromDate   .= ' ' . $obj->getParam( 'fromTime' ) if $fromDate;
  my $toDate   =       $obj->getParam( 'toDate'   );
  $toDate     .= ' ' . $obj->getParam( 'toTime'   ) if $fromDate;
  
  my $dateFormatter = $context->getDateFormatter();
  my $startEpoch = $fromDate  ?  $dateFormatter->dateTime2Epoch( $fromDate )  :  time-86400;
  my $endEpoch   = $toDate    ?  $dateFormatter->dateTime2Epoch( $toDate   )  :  time;
  
  my $query = "$startOfQuery from O2_CONSOLE_LOG where timestamp >= ? and timestamp <= ?";
  my @placeHolders = ($startEpoch, $endEpoch);
  if ($obj->getParam('type')) {
    $query .= ' and logType = ?';
    push @placeHolders, $obj->getParam('type');
  }
  if ($obj->getParam('filterOn') && $obj->getParam('filterMatch')) {
    my $filterOn = $obj->getParam('filterOn');
    die "Error in 'filterOn' parameter" if $filterOn =~ m{ \W }xms;
    
    $query .= " and " . $obj->getParam('filterOn') . ' = ?';
    push @placeHolders, $obj->getParam('filterMatch');
  }
  return ($query, \@placeHolders);
}
#------------------------------------------------------------------
sub getResults {
  my ($obj, $skip, $limit) = @_;
  my ($query, $placeHolders) = $obj->_buildQuery('select *');
  my $lines = $db->fetchAll("$query order by id desc limit $skip, $limit", @{$placeHolders});
  return @{$lines};
}
#------------------------------------------------------------------
sub resetConsole {
  my ($obj) = @_;
  $db->sql('truncate table O2_CONSOLE_LOG');
  $obj->init();
}
#------------------------------------------------------------------
sub deleteLogEntry {
  my ($obj) = @_;
  my $rowId = $obj->getParam('rowId');
  my ($id) = $rowId =~ m{ logRow (\d+) }xms;
  eval {
    $db->sql("delete from O2_CONSOLE_LOG where id = ?", $id);
  };
  if ($@) {
    $obj->error("Error deleting row: $@");
  }
  return 1;
}
#------------------------------------------------------------------
sub deleteByFilter {
  my ($obj) = @_;
  my ($query, $placeHolders) = $obj->_buildQuery('delete');
  $db->sql($query, @{$placeHolders});
  $cgi->redirect(
    setMethod    => 'init',
    removeParams => '1',
  );
}
#------------------------------------------------------------------
sub deleteRows {
  my ($obj) = @_;
  $db->sql('delete from O2_CONSOLE_LOG where id in (' . $obj->getParam('ids') . ')');
  $obj->init();
}
#------------------------------------------------------------------
sub deleteAllRowsBut {
  my ($obj) = @_;
  $db->sql('delete from O2_CONSOLE_LOG where id not in (' . $obj->getParam('ids') . ')');
  $obj->init();
}
#------------------------------------------------------------------
1;
