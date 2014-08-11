package O2Plugin::Shop::Backend::Gui::OrderTypeEditor;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi);

#--------------------------------------------------------------------------------------#
sub init {
  my ($obj, $message) = @_;
  $message ||= $obj->getParam('message');
  $obj->display(
    'orderTypes.html',
    orderTypes => [ $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager')->getOrderTypes() ],
    message    => $message,
  );
}
#--------------------------------------------------------------------------------------#
sub editOrderType {
  my ($obj) = @_;

  my $orderType = $context->getObjectById( $obj->getParam('orderTypeId') );

  if ($obj->getParam('action') eq 'copy') {
    $orderType->setId(undef);
    $orderType->setMetaName( 'COPY OF '.$orderType->getMetaName() );   
  }

  $obj->display(
    'editOrderType.html',
    orderType => $orderType,
  );
}
#--------------------------------------------------------------------------------------#
sub newOrderType {
  my ($obj) = @_;
  $obj->display(
    'editOrderType.html',
    orderType => $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager')->newObject(),
  );
}
#--------------------------------------------------------------------------------------#
sub saveOrderType {
  my ($obj) = @_;

  my $orderTypeMgr = $context->getSingleton('O2Plugin::Shop::Mgr::OrderTypeManager');
  my $orderTypeId = $obj->getParam('orderType.id');
  my $orderType   = $orderTypeId ? $context->getObjectById($orderTypeId) : $orderTypeMgr->newObject();

  require O2::Util::AccessorMapper;
  my $accessorMapper = O2::Util::AccessorMapper->new();
  my $orderTypePosted = $cgi->getStructure('orderType');
  $accessorMapper->setAccessors( $orderType, %{$orderTypePosted} );
  $orderType->save();

  $obj->display('donesaving.html');
}
#--------------------------------------------------------------------------------------#
sub deleteOrderType {
  my ($obj) = @_;
  my $message = 'The OrderType was deleted';

  my $orderType = $context->getObjectById( $obj->getParam('orderTypeId') );
  
  my @ids = $orderType->getOrderIds();
  my $numInUse = @ids;
  if ($numInUse) {
    $message = "Could not delete OrderType - it's in use by $numInUse orders";
  }
  else {
    $orderType->delete();
  }
  
  $obj->init($message);
}
#--------------------------------------------------------------------------------------#
1;
