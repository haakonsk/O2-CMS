package O2CMS::Obj::Site::Sitemap;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#----------------------------------------------------------------------
sub canMove {
  return 0;
}
#----------------------------------------------------------------------
sub getCronFirstTimeFormatted {
  my ($obj, $format) = @_;
  $format =~ s{%}{}xmsg;
  return $context->getDateFormatter()->dateFormat( $obj->getCronFirstTimeEpoch(), $format );
}
#----------------------------------------------------------------------
1;
