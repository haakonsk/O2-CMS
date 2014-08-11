package O2Plugin::Shop::Frontend::Gui::Transaction::BBS;

use strict;

use base 'O2::Gui';

use O2 qw($context $config $session);

#--------------------------------------------------------------------------------------------------
sub showBBSForm {
  my ($obj, $orderId) = @_;

  $orderId ||= $session->get('currentOrderId');
  my $order  = $context->getObjectById($orderId);

  my @orderLines = $order->getOrderLines();
  my $orderDescription = '';
  foreach my $orderLine ( @orderLines ) {
    $orderDescription .= $orderLine->getMetaName().'<br>';
  }

  $obj->display(
    'bbsForm.html',
    session          => $session,
    config           => $config->get('shop.transaction.bbs'),
    order            => $order,
    transaction      => $order->getTransaction(),
    orderDescription => $orderDescription,
  );
}
#--------------------------------------------------------------------------------------------------
1;
