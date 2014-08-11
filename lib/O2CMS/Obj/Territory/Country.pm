package O2CMS::Obj::Territory::Country;

use strict;

use base 'O2CMS::Obj::Territory';

use O2 qw($context $config);

#-------------------------------------------------------------------------------
# return localized name
sub getName {
  my ($obj) = @_;
  return $context->getLocale()->getTerritoryName( $obj->getCode() );
}
#-------------------------------------------------------------------------------
# use flag as icon
sub getIconUrl {
  my ($obj, $size) = @_;

  if (!$size) {
    my $code = lc $obj->getCode();
    my $path = $config->get('o2.root') . "/var/www/images/locale/flag_16x11/$code.gif";
    return "/images/locale/flag_16x11/$code.gif" if -e $path;
  }
  return $obj->SUPER::getIconUrl();
}
#-------------------------------------------------------------------------------
1;
