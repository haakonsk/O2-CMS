package O2Plugin::Shop::Obj::Transaction::PayPal::Direct;

use strict;

use base 'O2Plugin::Shop::Obj::Transaction::PayPal';

use O2 qw($context $config $session);
use Business::PayPal::API qw(DirectPayments);
use URI::Escape;

#----------------------------------------------------------------------------------------------
sub generatePaymentUrl {
  my ($obj, %params) = @_;
  
  # Here we must reserve the payment trough the Business::PayPal::API
  # Then we just return the returnUrl, since we do the reservation ourselves
  
  $obj->logEvent(
    'starting generatePaymentUrl',
    'info',
  );
  
  # Start the transaction in O2
  $obj->_beginTransaction(%params);
  
  my $sessionId = $session->getId();
    
  # Find and get the order
  my $transactionId = $obj->getId();
  my $orderId = $session->get('currentOrderId');
  
  # Die if no orderId is found
  if (!$orderId) {
    $obj->logEvent(
      'generatePaymentUrl says : no orderId found in session!',
      'error',
    );
    die "<b>No orderId found in session!</b>";
  }
  
  # Revive the order
  my $order = $context->getObjectById($orderId);
  
  if ( ref $order ne 'O2Plugin::Shop::Obj::Order' ) {
    $obj->logEvent(
      'generatePaymentUrl says : $order is not a O2Plugin::Shop::Obj::Order : ' . ref ($order),
      'error',
    );
    
    die;
  }
  
  # Read config data for communicating with PayPal - connection spesific
  my $directPaymentInfo = $config->get('paypal.directPayment');

  # Set up connection to PayPal
  my $payPalConnector = new Business::PayPal::API(
    Username  => $directPaymentInfo->{'username'},
    Password  => $directPaymentInfo->{'password'},
    Signature => $directPaymentInfo->{'signature'},
    sandbox   => $directPaymentInfo->{'sandbox'},
  );
  
  # Perform transaction - this is a Direct Payment
  # Note - correct case is über important here.
  
  my %response = $payPalConnector->DoDirectPaymentRequest(
    OrderTotal        => $order->getPriceIncVatExSubOrderLines(),#$params{amount},
    CreditCardType    => $params{creditCardType},
    CreditCardNumber  => $params{creditCardNumber},
    ExpMonth          => $params{expMonth},
    ExpYear           => $params{expYear},
    CVV2              => $params{cvv2},
    FirstName         => $params{firstName},#$order->getCustomerFirstname(),
    LastName          => $params{lastName},#$order->getCustomerLastname(),
    Street1           => $order->getCustomerAddress()     || 'no street',
    CityName          => $order->getCustomerPostalPlace() || 'no city',
    PostalCode        => $order->getCustomerPostalCode()  || 'no code',
    Country           => $order->getCustomerCountry(), # We _must_ pass over country code, eg. NO
    Payer             => $order->getCustomerEmail(),
    IPAddress         => $params{customerIP}, # XXX Perhaps add IP tracking?
    MerchantSessionID => $sessionId, # This is ok I hope?
    currencyID        => $params{currency},
  );
  
  if ( $response{'Ack'} eq 'Success' ) {
    # What to do when the transaction went well
    # Store PayPal's TransactionID ?
    if ( $response{'TransactionID'} ) {
      $obj->setExternalId( $response{'TransactionID'} );
      $obj->save();
      
      $obj->logEvent(
        'PayPal_CorrelationID: '.$response{'CorrelationID'}.', PayPal_TransactionID: '.$response{'TransactionID'},
        'info',
      );
    }
  }
 
  else {
    # We do nothing but store a log?
    require Data::Dumper;
    $obj->logEvent(
      "PayPal_CorrelationID: $response{CorrelationID}, PayPal says : " . Data::Dumper::Dumper( $response{Errors} ),
      'error',
    );
    
    # Maybe store in session as well?
    $session->set( paypalErrorMessage => $response{'Errors'}[0]{'LongMessage'} );
  }
    
  # Always return url
  return $params{returnUrl};
}
#----------------------------------------------------------------------------------------------
sub receivePayment {
  my ($obj, %params) = @_;

  $obj->logEvent(
    'starting receivePayment',
    'info',
  );
  
  # Here we must check the reservation trough the Business::PayPal::API
  # (If something went wrong in the genereatePaymentUrl - here is where we catch it
  #  in order to conform with the generic O2-transaction-API)
  
  my $paymentId = $obj->getExternalId();
  my $orderId = $session->get('currentOrderId');
  
  # Added logging of this die statement - FAM
  if (!$orderId) {
    $obj->logEvent(
      'receivePayment says : No orderId found in session!',
      'error',
    );
    
    die "<b>No orderId found in session!</b>";
  }
  
  my $order = $context->getObjectById($orderId);
  
  # Update Order with status
  if ($paymentId) {    
    $order->setStatus('completed');
  }
  else {
    $obj->logEvent(
      'receivePayment says : No paymentId found!',
      'error',
    );
    
    $order->setStatus('failedToReceivePayment');
  }
  $order->save();  
  
  # Transform paymentId into reserved or error
  $obj->_endTransaction( $paymentId ? 'reserved' : 'error' );
  return $paymentId;
}
#----------------------------------------------------------------------------------------------
1;
