package O2Plugin::Shop::Obj::Transaction::BBS;

# This module provides transaction support for BBS transactions. This it the new version supporting the new REST API

use strict;

use base 'O2Plugin::Shop::Obj::Transaction';

use O2 qw($context $cgi $config $session);
use REST::Client;

#--------------------------------------------------------------------------------------------------
# The initializer, sets up everything ready for use
sub new {
  my ($package, %params) = @_;
  
  my $manager = delete $params{manager};
  my $obj     = $package->SUPER::new(manager => $manager);
  my $config  = $manager->getContext()->getConfig();
  
  # Read the config-parameters for the connection
  # Note: this data is user specific
  $obj->{configuration} = $config->get('shop.transaction.bbs');
  
  # Must die if we cannot locate the configuration file.
  die 'Could not load configuration!' unless ($obj->{configuration});
  
  # Also verify that elements are present in config
  # Customer spesifics
  die 'Missing token!'      unless ( $obj->{configuration}->{token}      );
  die 'Missing merchantId!' unless ( $obj->{configuration}->{merchantId} );
  
  %params = ( %{$obj->{configuration}}, %params );
  
  # Create REST client
  my $client     = REST::Client->new();
  $obj->{client} = $client;
  
  return $obj;
}
#--------------------------------------------------------------------------------------------------
sub generatePaymentUrl {
  # This function register the transaction at BBS, then based on the result, create an
  # URL which we can redirect the user into BBS with.
  my ($obj, %params) = @_;
  
  # If provided with an user object, we extract data and store it on (this transaction) ourselves
  if ( $params{member} ) {
    my $member = delete $params{member};
    $obj->setMetaInfo(
      address1    => $member->getAddress(),
      postalCode  => $member->getPostalCode(),
      city        => $member->getPostalPlace(),
      country     => $member->getCountryCode(),
      firstName   => $member->getFirstName(),
      middleName  => $member->getMiddleName(),
      lastName    => $member->getLastName(),
      phoneNumber => $member->getPhone(),
    );
  }
  
  # Trigger the registration of a new transaction
  $obj->_beginTransaction(
    %params,
    token      => $obj->{configuration}->{token},
    merchantId => $obj->{configuration}->{merchantId},
    currency   => $obj->{configuration}->{currencyCode},
  );
  
  # Register payment with BBS to get the BBSTransactionId. This ID must follow any additional calls to BBS for this payment
  my $BBSTransactionId = $obj->_register();
  
  if ($BBSTransactionId) {
    # We got the setup code and we can now stich together the paymentURL
    my $paymentUrl =
       "$obj->{configuration}->{URL}->{payment}"
      . "?merchantId=$obj->{configuration}->{merchantId}"
      . "&transactionId=$BBSTransactionId"
    ;
    
    # We have to remember the setup code for later on
    $session->set( BBSTransactionId => $BBSTransactionId );
    $session->save();
    
    # Note that this might be a bit long
    $obj->logEvent("BBSTransactionId: $BBSTransactionId", 'info');
    
    # Pass along the created URL
    return $paymentUrl;
  }
  else {
    # Could not create the URL, maybe the response is wrong?
    $obj->logEvent('BBSTransactionId unavailable', 'error');
    $obj->_endTransaction( 'cancelled' );
    
    # Return nothing
    return;
  }
}
#--------------------------------------------------------------------------------------------------
sub receivePayment {
  # This function will normally be run when a customer returns to the application after being
  # processed at BBS. It will run the Auth operation so that the order amount can be reserved
  my ($obj, %params) = @_;
  
  my $transactionString = $cgi->getParam('BBSePay_transaction');
  
  my $authorizationId = $obj->_process('AUTH');
  
  if ($authorizationId) {
    # log the authorizationId as well as saving it on the transaction
    $obj->logEvent("AuthorizationId: $authorizationId", 'info');
    $obj->setExternalId($authorizationId);
    $obj->save();
    
    # reservation
    my $paymentId = $obj->_endTransaction('reserved');
    
    # We need the issuerId, it tells us what kind of card was used
    my $issuerId = $obj->getPaymentInfo('issuerId');
    
    if ($issuerId) {
      $session->set( 'IssuerId' => $issuerId );
      $session->save();
    }
    
    if (!$paymentId) {
      $obj->logEvent('_endTransaction returned no paymentId', 'error');
      $obj->_endTransaction('cancelled');
    }
    return $paymentId;
  }
  else {
    # There was an error - cancel the transaction
    $obj->_endTransaction('cancelled') if $obj->getStatus() ne 'reserved';
    
    # Log and die
    $obj->logEvent('missing authorizationId', 'error');
    die "Missing authorizationId\n";
  }
}
#--------------------------------------------------------------------------------------------------
sub getPaymentInfo {
  my ($obj, $fieldName) = @_;
  
  # To get payment information we now need to perform a query into BBS
  my $paymentInfo = $obj->_query();
  
  # Lets look at the card information
  my $issuerId;
  my ($cardInfo) = $paymentInfo =~ m/<CardInformation>(.*)<\/CardInformation>/xms;
  ($issuerId)    = $cardInfo    =~ m/<Issuer>(.*)<\/Issuer>/xms if $cardInfo;
  
  return $issuerId if $issuerId;
}
#--------------------------------------------------------------------------------------------------
# Note, the following functions are internal and should not be called from outside BBS.pm
#--------------------------------------------------------------------------------------------------
# This method calls REGISTER at BBS and collects an transactionId from BBS to be used when creating the paymentURL
sub _register {
  my ($obj) = @_;
  
  my $registerURL = $obj->{configuration}->{URL}->{register}
    . '?MerchantId='    .  $obj->{configuration}->{merchantId}
    . '&token='         .  $obj->{configuration}->{token}
    . '&orderNumber='   .  $obj->getOrderId()
    . '&amount='        . ($obj->getAmount() * 100) # BBS requirement
    . '&CurrencyCode='  .  $obj->getCurrency()
    . '&redirectUrl='   .  $obj->getReturnUrl()
    . '&customerEmail=' .  $obj->getOrder()->getCustomerEmail()
    . '&transactionId=' .  $obj->getId()
  ;
  
  $obj->{client}->GET($registerURL);
  
  $obj->handleComFailure() if $obj->{client}->responseCode() ne 200;
  
  my $response        = $obj->{client}->responseContent();
  my ($transactionId) = $response =~ m|<TransactionId>(.*)</TransactionId>|ms;
  
  return $transactionId;
}
#--------------------------------------------------------------------------------------------------
# This is a wrapper function capable of performing all BBS operations, just send $operation and add exceptions if needed for return values. If no exception is provided you will receive the BBS response XML
sub _process {
  my ($obj, $operation) = @_;
  
  my $processURL = $obj->{configuration}->{URL}->{process}
    . '?MerchantId='     . $obj->{configuration}->{merchantId}
    . '&token='          . $obj->{configuration}->{token}
    . '&transactionId='  . $session->get('BBSTransactionId')
    . '&operation='      . $operation
  ;
  $obj->{client}->GET($processURL);
  $obj->handleComFailure() if $obj->{client}->responseCode() ne 200;
  
  my $response = $obj->{client}->responseContent();
  if ($operation eq 'AUTH') {
    my ($authorizationId) = $response =~ m|<AuthorizationId>(.*)</AuthorizationId>|ms;
    return $authorizationId;
  }
  
  return $response;
}
#--------------------------------------------------------------------------------------------------
sub _query {
  my ($obj) = @_;
  
  my $BBSTransactionId = $session->get('BBSTransactionId');
  
  my $queryURL = $obj->{configuration}->{URL}->{query}
    .'?MerchantId='    .$obj->{configuration}->{merchantId}
    .'&token='         .$obj->{configuration}->{token}
    .'&transactionId=' .$BBSTransactionId
  ;
  
  $obj->{client}->GET($queryURL);
  
  $obj->handleComFailure() if $obj->{client}->responseCode() ne 200;
  
  my $response = $obj->{client}->responseContent();
  
  return $response;
}
#--------------------------------------------------------------------------------------------------
sub handleComFailure {
  my ($obj) = @_;
  die 'BBS: Communication failure, code: '.$obj->{client}->responseCode().', content: '.$obj->{client}->responseContent()."\n";
}
#------------------------------------------------------------------------------
1;
