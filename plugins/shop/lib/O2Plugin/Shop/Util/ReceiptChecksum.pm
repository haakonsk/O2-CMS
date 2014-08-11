package O2Plugin::Shop::Util::ReceiptChecksum;

use strict;

#-----------------------------------------------------------------------------------------
sub new {
  return bless {}, shift;
}
#-----------------------------------------------------------------------------------------
sub checksum {
  my ($obj, $id) = @_;
  $id = $obj unless ref $obj;
  my $checkSum = substr crypt ($id, ')9'), 2; # XXX Rewrite to something more clever, and refactor out to a common module
  $checkSum    =~ s/(\W)/sprintf ("%lx", ord $1)/ge;
  return $checkSum;
}
#-----------------------------------------------------------------------------------------
1;
