package O2Plugin::Shop::Obj::Transaction::PayPal;

use strict;

use base 'O2Plugin::Shop::Obj::Transaction';

#----------------------------------------------------------------------------------------------
sub generatePaymentUrl {
  die "This is an abstract method";
}
#----------------------------------------------------------------------------------------------
sub receivePayment {
  die "This is an abstract method";
}
#----------------------------------------------------------------------------------------------
1;
