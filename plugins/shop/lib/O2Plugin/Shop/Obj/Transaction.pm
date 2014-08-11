package O2Plugin::Shop::Obj::Transaction;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context $config $db);

#--------------------------------------------------------------------------------------------
sub getOrder {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getOrderId() );
}
#--------------------------------------------------------------------------------------------
sub generatePaymentUrl {
  my ($obj, %params) = @_;
  die "This is an abstract class, and this method must be inherited";
}
#--------------------------------------------------------------------------------------------
sub receivePayment {
  my ($obj, %params) = @_;
  die "This is an abstract class, and this method must be inherited";
}
#--------------------------------------------------------------------------------------------
sub setMetaInfo {
  my ($obj, %params) = @_;
  foreach my $key (keys %params) {
    $obj->{metaInfo}->{$key} = $params{$key};
  }
}
#--------------------------------------------------------------------------------------------
sub _beginTransaction { # Logs the request
  my ($obj, %params) = @_;
  
  my $orderId = $params{orderId} || $params{orderNumber} || $obj->getOrderId() || 0;
  $obj->setMetaName(  __PACKAGE__               );
  $obj->setReturnUrl( delete $params{returnUrl} );
  $obj->setAmount(    delete $params{amount}    ) if $params{amount};
  $obj->setCurrency(  delete $params{currency}  );
  $obj->setOrderId(   $orderId                  );
  $obj->setDate(      $obj->date()              );
  $obj->setStatus(    'created'                 );
  $obj->save();

  $obj->setMetaInfo(%params);

  die "No 'returnUrl' specified" unless $obj->getReturnUrl();
#  die "No 'amount' specified"    unless $obj->getAmount(); # XXX Should it be possible to pay 0?

  # XXX Do something if we could not insert the transaction. Write to file?

  $obj->logEvent("Starting transaction", 'info');
}
#--------------------------------------------------------------------------------------------
sub _endTransaction {
  my ($obj, $status, $paymentId) = @_;

  # XXX What to do in case of error?
  # XXX Check to see that we actually have a transaction of the same transactionId

  if ($status eq 'reserved' || $status eq 'completed') {
    $obj->logEvent("_endTransaction ok, status set to '$status' (paymentId: " . $obj->getExternalId() . ')', 'info');
    $obj->setStatus($status);
    $obj->save();
    return $obj->getExternalId();
  }

  my $toEmails = $config->get('o2.onFailedTransactionSendEmailTo');

  if ($toEmails) {
    require O2::Util::SendMail;
    my $mailer = O2::Util::SendMail->new();
    $mailer->send(
      to      => $toEmails,
      from    => $config->get('o2.smtpSender'),
      subject => $context->getLang()->getString('Shop.Transaction.failedTransactionEmailSubject'),
      body    => $context->getLang()->getString(
        'Shop.Transaction.failedTransactionEmailBody',
        status        => $status,
        orderId       => $obj->getOrderId(),
        transactionId => $obj->getId(),
        amount        => $obj->getAmount(),
        currency      => $obj->getCurrency(),
        date          => $obj->getDate(),
      ),
      html => 1,
    );
  }
  $obj->logEvent("Transaction failed, status set to '$status' (paymentId: " . $obj->getExternalId() . ')', 'warning');
  $obj->setStatus($status);
  $obj->save();
  return 0;
}
#--------------------------------------------------------------------------------------------
sub getReturnUrl {
  my ($obj) = @_;
  return $obj->{returnUrl};
}
#--------------------------------------------------------------------------------------------
sub setReturnUrl {
  my ($obj, $value) = @_;
  $obj->{returnUrl} = $value;
}
#--------------------------------------------------------------------------------------------
sub logEvent {
  my ($obj, $event, $type) = @_;
  my $transactionId = $obj->getId() || 0;
  my $timestamp = time;
  my $clientIP = $context->getClientIp() || $context->getEnv('USER') || '';

  $db->do(
    "insert into O2PLUGIN_SHOP_OBJ_TRANSACTION_LOG (objectId, clientIdentifier, type, message, epochTime) values (?, ?, ?, ?, ?)",
    $transactionId, $clientIP, $type, $event, $timestamp,
  );
}
#--------------------------------------------------------------------------------------------
sub getLogEntries {
  my ($obj) = @_;
  return $db->fetchAll( "select * from O2PLUGIN_SHOP_OBJ_TRANSACTION_LOG where objectId = ?", $obj->getId() );
}
#--------------------------------------------------------------------------------------------
sub date {
  my ($d, $m, $y) = (localtime)[3,4,5];
  return sprintf "%.4d%.2d%.2d", $y+1900, $m+1, $d;
}
#--------------------------------------------------------------------------------------------
sub getIndexableFields {
  my ($obj) = @_;
  return ($obj->SUPER::getIndexableFields(), 'externalId');
}
#--------------------------------------------------------------------------------------------

1;
__END__

Statuses:
created
reserved
completed
captureError
confirmError
cancelled

Types:
test
production
warning
error
info
etc. (I think)

