package O2Plugin::Shop::Mgr::ReceiptManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Receipt;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Receipt',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    serializedObject => { type => 'mediumtext' },
    vatPercentage    => { type => 'float'      },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub createReceipt {
  my ($obj, $orderLine) = @_;
  my $product = $orderLine->getProduct();
  die "Product " . $product->getMetaName() . " (" . ref ($product) . ") is not serializable" unless $product->isSerializable();
  my $receipt = $obj->newObject();
  $receipt->setMetaName(         $orderLine->getMetaName()    );
  $receipt->setSerializedObject( $product->serialize()        );
  $receipt->setVatPercentage(    $product->getVatPercentage() );
  $receipt->save();
  $orderLine->setReceiptId( $receipt->getId() );
  $orderLine->save();
  return $receipt;
}
#----------------------------------------------------------------------------
1;
