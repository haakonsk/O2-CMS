package O2Plugin::Shop::Obj::ProductType;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub setName {
  my ($obj, $name) = @_;
  $obj->setModelValue('name', $name);
  $obj->setMetaName($name) if $obj->getCurrentLocale() eq $context->getLocaleCode();
}
#-----------------------------------------------------------------------------
1;
