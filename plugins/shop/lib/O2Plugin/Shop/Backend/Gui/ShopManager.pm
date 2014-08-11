package O2Plugin::Shop::Backend::Gui::ShopManager;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $session);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $session->set('o2ShopHistory', undef);
  my $orderTypeMgr = $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager');
  my @transactionStatuses = $context->getSingleton('O2Plugin::Shop::Mgr::TransactionManager')->search()->getDistinct('status');
  $obj->display(
    'init.html',
    orderStatuses       => { $orderTypeMgr->getAvailableStatusesAsHash() },
    orderTypes          => [ $orderTypeMgr->getOrderTypes()              ],
    transactionStatuses => \@transactionStatuses,
    today               => $context->getDateFormatter()->dateFormat(time, 'yyyy-MM-dd'),
  );
}
#-----------------------------------------------------------------------------
sub search {
  my ($obj) = @_;
  $obj->{previousUrl} = $obj->_updateHistory();
  my $searchQuery = $obj->getParam('query');
  if ($searchQuery =~ m{ \A \d+ \z }xms) {
    my $object = $context->getObjectById($searchQuery);
    return $obj->_displayObject($object) if $object;
  }
  $obj->display(
    'searchResults.html',
    gui         => $obj,
    previousUrl => $obj->{previousUrl},
  );
}
#-----------------------------------------------------------------------------
sub getSearchResults {
  my ($obj, $skip, $limit, $searchQuery, $className) = @_;
  $className =~ s{::}{_}xmsg; # Since swish doesn't index words containing colons..
  $searchQuery .= " $className" if $className;
  my $searcher = $context->getSingleton('O2CMS::Search::Query', indexName => 'o2Shop');
  $searcher->setRange($skip, $skip+$limit);
  my $results = $searcher->search($searchQuery);
  $obj->_setTotalNumRegularSearchResults( $results->getNumHits() );
  my @objects = map  { $context->getObjectById( $_->getId() ) }  $results->getAllResults();
  return @objects;
}
#-----------------------------------------------------------------------------
sub _setTotalNumRegularSearchResults {
  my ($obj, $numResults) = @_;
  $obj->{totalNumRegularSearchResults} = $numResults;
}
#-----------------------------------------------------------------------------
sub getTotalNumRegularSearchResults {
  my ($obj) = @_;
  return $obj->{totalNumRegularSearchResults};
}
#-----------------------------------------------------------------------------
sub orderSearch {
  my ($obj) = @_;
  $obj->{previousUrl} = $obj->_updateHistory();
  $obj->display(
    'orderSearchResults.html',
    gui         => $obj,
    previousUrl => $obj->{previousUrl},
  );
}
#-----------------------------------------------------------------------------
sub getOrderSearchResults {
  my ($obj, $skip, $limit) = @_;
  my %q = $obj->getParams();
  my $orderStruct = $cgi->getStructure('order');
  my %searchParams;
  %searchParams = %{$orderStruct} if $orderStruct;
  foreach my $key (keys %searchParams) {
    delete $searchParams{$key} unless $searchParams{$key};
  }
  $searchParams{'customerId->firstName'} = $q{firstName} if $q{firstName};
  $searchParams{'customerId->lastName'}  = $q{lastName}  if $q{lastName};
  $searchParams{'customerId->email'}     = $q{email}     if $q{email};
  $searchParams{objectId}                = $q{orderId}   if $q{orderId};
  if ($q{orderLineId}) {
    my $orderLine = $context->getObjectById( $q{orderLineId} );
    $searchParams{objectId} = $orderLine->getOrderId() if $orderLine;
  }
  if ($q{username}) {
    my $member = $context->getSingleton('O2::Mgr::MemberManager')->getMemberByUsername( $q{username} );
    $searchParams{customerId} = $member->getId() if $member;
  }
  my $dateFormatter = $context->getDateFormatter();
  $searchParams{metaCreateTime} = {} if $q{fromDate} || $q{toDate};
  $searchParams{metaCreateTime}->{ge} = $dateFormatter->dateTime2Epoch( $q{fromDate} )            if $q{fromDate};
  $searchParams{metaCreateTime}->{le} = $dateFormatter->dateTime2Epoch( $q{toDate}   ) + 24*60*60 if $q{toDate};
  $searchParams{-skip}    = $skip  if $skip;
  $searchParams{-limit}   = $limit if $limit;
  $searchParams{-orderBy} = 'objectId desc';
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->objectSearch(%searchParams);
}
#-----------------------------------------------------------------------------
sub getTotalNumOrderSearchResults {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->getTotalNumSearchResults();
}
#-----------------------------------------------------------------------------
sub transactionSearch {
  my ($obj) = @_;
  $obj->{previousUrl} = $obj->_updateHistory();
  $obj->display(
    'transactionSearchResults.html',
    gui         => $obj,
    previousUrl => $obj->{previousUrl},
  );
}
#-----------------------------------------------------------------------------
sub getTransactionSearchResults {
  my ($obj, $skip, $limit) = @_;
  my %q = $obj->getParams();
  my %searchParams = %{ $cgi->getStructure('transaction') };
  foreach my $key (keys %searchParams) {
    delete $searchParams{$key} unless $searchParams{$key};
  }
  $searchParams{status} = { in => $searchParams{status} } if @{ $searchParams{status} };
  $searchParams{amount} = {} if length $q{amountMin} || length $q{amountMax};
  $searchParams{amount}->{ge} = $q{amountMin} if length $q{amountMin};
  $searchParams{amount}->{le} = $q{amountMax} if length $q{amountMax};
  my $dateFormatter = $context->getDateFormatter();
  $searchParams{metaCreateTime} = {} if $q{fromDate} || $q{toDate};
  $searchParams{metaCreateTime}->{ge} = $dateFormatter->dateTime2Epoch( $q{fromDate} )            if $q{fromDate};
  $searchParams{metaCreateTime}->{le} = $dateFormatter->dateTime2Epoch( $q{toDate}   ) + 24*60*60 if $q{toDate};
  $searchParams{-skip}  = $skip  if $skip;
  $searchParams{-limit} = $limit if $limit;
  return $context->getSingleton('O2Plugin::Shop::Mgr::TransactionManager')->objectSearch(
    -orderBy => 'objectId desc',
    %searchParams,
  );
}
#-----------------------------------------------------------------------------
sub getTotalNumTransactionSearchResults {
  my ($obj) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::TransactionManager')->getTotalNumSearchResults();
}
#-----------------------------------------------------------------------------
sub customerSearch {
  my ($obj) = @_;
  $obj->{previousUrl} = $obj->_updateHistory();
  my $template
    = $obj->getParam('displayMethod') eq 'addresses'      ? 'customerSearchResultsAddresses.html'
    : $obj->getParam('displayMethod') eq 'addressesExcel' ? 'customerSearchResultsAddresses.html'
    :                                                       'customerSearchResultsOverview.html'
    ;
  my $displayMethod = $obj->getParam('displayMethod') eq 'addressesExcel' ? 'displayExcel' : 'display';
  $obj->$displayMethod(
    $template,
    ordersOrOrderLines => [ $obj->getCustomerSearchResults() ],
    previousUrl        => $obj->{previousUrl},
  );
}
#-----------------------------------------------------------------------------
sub getCustomerSearchResults {
  my ($obj) = @_;
  my %q = $obj->getParams();
  my %searchParams = %{ $cgi->getStructure('customer') };
  foreach my $key (keys %searchParams) {
    delete $searchParams{$key}                                 unless $searchParams{$key};
    $searchParams{"customerId->$key"} = delete $searchParams{$key} if $searchParams{$key}
  }
  my $dateFormatter = $context->getDateFormatter();
  $searchParams{metaCreateTime} = {} if $q{fromDate} || $q{toDate};
  $searchParams{metaCreateTime}->{ge} = $dateFormatter->dateTime2Epoch( $q{fromDate} )            if $q{fromDate};
  $searchParams{metaCreateTime}->{le} = $dateFormatter->dateTime2Epoch( $q{toDate}   ) + 24*60*60 if $q{toDate};
  my @orders     = $context->getSingleton( 'O2Plugin::Shop::Mgr::OrderManager'     )->objectSearch(%searchParams);
  my @orderLines = $context->getSingleton( 'O2Plugin::Shop::Mgr::OrderLineManager' )->objectSearch(%searchParams);
  my @ordersOrOrderLines = (@orders, @orderLines);
  @ordersOrOrderLines = grep { $_->getCustomerId() && $_->getCustomer() } @ordersOrOrderLines;
  @ordersOrOrderLines = sort {
       $a->getCustomerLastName()   cmp $b->getCustomerLastName()
    || $a->getCustomerFirstName()  cmp $b->getCustomerFirstName()
    || $a->getCustomerMiddleName() cmp $b->getCustomerMiddleName()
  } @ordersOrOrderLines if $q{sortBy} eq 'name';
  @ordersOrOrderLines = sort { $b->getMetaCreateTime() <=> $a->getMetaCreateTime() } @ordersOrOrderLines if $q{sortBy} eq 'date';
  return @ordersOrOrderLines;
}
#-----------------------------------------------------------------------------
sub _displayObject {
  my ($obj, $object) = @_;
  return $obj->_displayNoResults() unless $object;
  $obj->display(
    $obj->_getTemplate($object),
    object      => $object,
    gui         => $obj,
    previousUrl => $obj->{previousUrl},
  );
}
#-----------------------------------------------------------------------------
sub _getTemplate {
  my ($obj, $object) = @_;
  return
      $object->isa('O2::Obj::Person')                  ? 'person.html'
    : $object->isa('O2Plugin::Shop::Obj::Order')       ? 'order.html'
    : $object->isa('O2Plugin::Shop::Obj::OrderLine')   ? 'orderLine.html'
    : $object->isa('O2Plugin::Shop::Obj::Transaction') ? 'transaction.html'
    : $object->isa('O2Plugin::Shop::Obj::Product')     ? 'product.html'
    :                                                    'object.html'
    ;
}
#-----------------------------------------------------------------------------
sub getOrdersByPersonId {
  my ($obj, $personId) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderManager')->objectSearch(
    customerId => $personId,
  );
}
#-----------------------------------------------------------------------------
sub getOrderLinesByPersonId {
  my ($obj, $personId) = @_;
  return $context->getSingleton('O2Plugin::Shop::Mgr::OrderLineManager')->objectSearch(
    customerId => $personId,
  );
}
#-----------------------------------------------------------------------------
sub manuallyConfirmTransaction {
  my ($obj) = @_;
  my $transaction = $context->getObjectById( $obj->getParam('transactionId') );
  $transaction->setStatus('completed');
  $transaction->logEvent('Transaction was manually approved', 'info');
  $transaction->save();
  $cgi->redirect(
    setMethod => 'search',
    setParams => 'query=' . $transaction->getId(),
  );
}
#-----------------------------------------------------------------------------
sub _displayNoResults {
  my ($obj) = @_;
  $obj->display(
    'noResults.html',
    previousUrl     => $obj->{previousUrl},
    includeBackLink => 1,
  );
}
#-----------------------------------------------------------------------------
sub _updateHistory {
  my ($obj) = @_;
  my $frame = $obj->getParam('frame');
  my $currentUrl = $context->getEnv('REQUEST_URI');
  my $history = $session->get('o2ShopHistory') || {};
  $history->{$frame} = [] unless $history->{$frame};
  my $frameHistory = $history->{$frame};
  if ($frameHistory->[-2] && $frameHistory->[-2] eq $currentUrl) { # User may have clicked back link
    pop @{$frameHistory};
  }
  else {
    push @{$frameHistory}, $currentUrl if $currentUrl ne $frameHistory->[-1];
  }
  $session->set('o2ShopHistory', $history);
  return $frameHistory->[-2] if $frameHistory->[-2];
  return;
}
#-----------------------------------------------------------------------------
1;
