package O2Plugin::Shop::Obj::Transaction::PayPal::Express;

use strict;

use base 'O2Plugin::Shop::Obj::Transaction::PayPal';

use O2 qw($context $config $session);
use Business::PayPal::API::ExpressCheckout;

#---------------------------------------------------------------------------------------------------------------------------------------------------
sub generatePaymentUrl {
  my ($obj, %params) = @_;

  # Start the transaction in O2
  $obj->_beginTransaction(%params);
  
  # Find and get the order, die if no order is found
  my $orderId = $session->get('currentOrderId') or die "<b>No orderId found in session!</b>";
  my $order = $context->getObjectById($orderId);
  
  # Read config data for communicating with PayPal
  my $expressPaymentInfo = $config->get('paypal.expressPayment');
  
  # Perform connection to PayPal and collect token
  my $token = $obj->_sendRequestAndGetToken($order);
    
  # Add token to url (to redirect customer) and return it
  if ($token) {
    # Store the token in the session for future reference.
    # Totally unneccesary because these values are passed to GUI by PayPal itself
    $session->set( expressToken => $token );
    
    # Return the paypal url and stick the token to it.
    return "$expressPaymentInfo->{paypalUrl}&token=$token";
  }
  
  # We have no token, no point in continuing this charade
  else {
    $session->set( expressToken => '' );
    my $errorMessage = 'Communication with PayPal failed!';
    # Urlencode the error message, just in case
    $errorMessage =~ s/([^A-Za-z0-9])/sprintf ("%%%02X", ord $1)/seg;
    return "$expressPaymentInfo->{cancelUrl}?reason=$errorMessage";    
  }
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
sub receivePayment {
  my ($obj) = @_;
  
  my $token   = $session->get('expressToken');
  my $payerId = $session->get('expressPayerId');

  if (!$token || !$payerId){
    return 'Error: No PayPal credentials found.'; # We just need those two, sorry.
  }
  
  # If we have both token and payerId, we might log it
  $obj->logEvent("PayPal_expressToken: $token, PayPal_expressPayerId: $payerId", 'info');
  
  # Fetch order and get the sum agreed upon
  my $orderId = $session->get('currentOrderId');
  
  # Return with error message if no orderId
  return 'Error: No order found.' unless $orderId;
  
  my $order = $context->getObjectById($orderId);
  my $orderTotal = $order->getPriceIncVatExSubOrderLines();    
  my $payPalConnector = $obj->_getPayPalConnection();
   
  my %response = $payPalConnector->DoExpressCheckoutPayment(
    Token          => $token,
    PaymentAction  => 'Sale',
    PayerID        => $payerId,
    OrderTotal     => $orderTotal,
    currencyID     => $obj->getCurrency(),
  );

  # Check the result
  my $result;
  if ( $response{Ack} eq 'Success' ) {
    # What to do when the transaction went well
    # Store PayPal's TransactionID ?
    if ( $response{TransactionID} ) {
      $obj->setExternalId( $response{TransactionID} );
      $obj->save();
      $obj->logEvent("PayPal_CorrelationID: $response{CorrelationID}, PayPal_TransactionID: $response{TransactionID}", 'info');
      
      $result = 'success';
      $order->setStatus('completed');
    }
    $order->save();
    $obj->_endTransaction('reserved');
  }
 
  else {
    # We do nothing but store a log?
    $obj->logEvent("PayPal_CorrelationID: $response{CorrelationID}, PayPal_ErrorCode: $response{Errors}[0]{ErrorCode}, PayPal_ErrorMessage: $response{Errors}[0]{LongMessage}", 'error');
    
    $order->setStatus('failedToReceivePayment');
    $result = $response{Errors}[0]{LongMessage};
    $order->save();
    $obj->_endTransaction('error');
  }
  
  return $result;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
# This function will make a request to PayPal that we want to perform our transaction
# If ok, PayPal will return a token which we can use to redirect our customer into
# the PayPal system.
sub _sendRequestAndGetToken {
  my ($obj, $order) = @_;
  
  # Read config data for communicating with PayPal  
  my $expressPaymentInfo = $config->get('paypal.expressPayment');
  my $payPalConnector = $obj->_getPayPalConnection();
  
  # Valid fields for Express Checkout - kinda nice to have, eh?
  # ---------------------------------
  # Token
  # OrderTotal
  # currencyID
  # MaxAmount
  # OrderDescription
  # Custom
  # InvoiceID
  # ReturnURL
  # CancelURL
  # Address
  # ReqConfirmShipping
  # NoShipping
  # AddressOverride
  # LocaleCode
  # PageStyle
  # 'cpp-header-image'
  # 'cpp-header-border-color'
  # 'cpp-header-back-color'
  # 'cpp-payflow-color'
  # PaymentAction
  # BuyerEmail
  
  my $orderTotal = $order->getPriceIncVatExSubOrderLines();
  
  my %currencyMapping = (
    'GBP' => '£',
    'USD' => '$',
    'EUR' => '&#8364;',
  );
  
  my $orderDescription = ucfirst $session->get('currentItemName'); # XXX Horrible
  die 'Order description missing' unless $orderDescription;
  
  $orderDescription .= ', ' . $currencyMapping{ $obj->getCurrency() } . $orderTotal;
  
  my %response = $payPalConnector->SetExpressCheckout(
    OrderTotal       => $orderTotal,
    currencyID       => $obj->getCurrency(),
    OrderDescription => $orderDescription, # XXX Must fix this - how do I get order description ?
    ReturnURL        => $expressPaymentInfo->{returnUrl},
    CancelURL        => $expressPaymentInfo->{cancelUrl},
    NoShipping       => $expressPaymentInfo->{noShipping},
    BuyerEmail       => $order->getCustomerEmail(),
    PageStyle        => $expressPaymentInfo->{pageStyle},# Only use first PayPal layout - use PayPal to change settings
  );
  
  # We get a token from PayPal which we must use when we redirect our customer to, erm, PayPal  
  if ( $response{Ack} eq 'Success' ) {
    # Log success and token
    $obj->logEvent("PayPal_CorrelationID: $response{CorrelationID}, PayPal_ExpressToken: $response{Token}", 'info');
    
    # Everything was a big success, we can return the token
    return $response{Token};
  }
  else {
    # Logging the error 
    $obj->logEvent("PayPal_CorrelationID: $response{CorrelationID}, PayPal_ErrorCode: $response{Errors}[0]{ErrorCode}, PayPal_ErrorMessage: $response{Errors}[0]{LongMessage}", 'error');
    
    # No token? Return nothing.
    return '';
  }
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
# This function can give us details that PayPal has based on an token
# Might be useful?
sub getExpressCheckoutDetails {
  my ($obj, %params) = @_;
  my $token = $params{token};  

  # Set up connection to PayPal
  my $payPalConnector = $obj->_getPayPalConnection();
  
  my %details;
  %details = $payPalConnector->GetExpressCheckoutDetails($token) if $token;
  return \%details;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
# This function will connect to PayPal and return the object
sub _getPayPalConnection {
  my ($obj, %params) = @_;
  my $expressPaymentInfo = $config->get('paypal.expressPayment');

  # Set up connection to PayPal
  my $payPalConnector = new Business::PayPal::API::ExpressCheckout(
    Username  => $expressPaymentInfo->{username},
    Password  => $expressPaymentInfo->{password},
    Signature => $expressPaymentInfo->{signature},
    sandbox   => $expressPaymentInfo->{sandbox},
  );
  
  return $payPalConnector;
}
#---------------------------------------------------------------------------------------------------------------------------------------------------
1;
