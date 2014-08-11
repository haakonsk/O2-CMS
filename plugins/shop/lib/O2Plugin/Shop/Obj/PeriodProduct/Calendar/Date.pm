package O2Plugin::Shop::Obj::PeriodProduct::Calendar::Date;

use strict;

use base 'O2::Obj::DateTime';

use O2 qw($context);
use O2::Util::List qw(upush);

#-----------------------------------------------------------------------------
sub setAttribute {
  my ($obj, $key, $value) = @_;
  my %attributes = $obj->getAttributes();
  $attributes{$key} = $value;
  $obj->setAttributes(%attributes);
}
#-----------------------------------------------------------------------------
sub getAttribute {
  my ($obj, $key) = @_;
  my %attributes = $obj->getAttributes();
  return $attributes{$key};
}
#-----------------------------------------------------------------------------
sub getCalendar {
  my ($obj) = @_;
  return $context->getObjectById( $obj->getCalendarId() );
}
#-----------------------------------------------------------------------------
sub getProduct {
  my ($obj) = @_;
  return $obj->getCalendar()->getProduct();
}
#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
1;
