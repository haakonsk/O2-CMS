package O2CMS::Obj::Template::Object; # Description: Template for displaying an object. One template may be used for several classes.

use strict;

use base 'O2CMS::Obj::Template';

use O2 qw($context);
use O2::Util::List qw(upush contains);

#-------------------------------------------------------------------------------
sub addUsableClass {
  my ($obj, $usableClass) = @_;
  my @usableClasses = $obj->getUsableClasses();
  upush @usableClasses, $usableClass;
  $obj->setUsableClasses(@usableClasses);
}
#-------------------------------------------------------------------------------
# Returns true if template may be used for objects of a class
# If the template is usable for a super class of the given class, it's also usable for the given class
sub isUsableForClass {
  my ($obj, $className) = @_;
  my $objectIntrospect = $context->getSingleton('O2::Util::ObjectIntrospect');
  $objectIntrospect->setClass($className);
  my @classNames = ( $className, $objectIntrospect->getInheritedClasses() );
  my @usableClasses = $obj->getUsableClasses();
  foreach my $_className (@classNames) {
    return 1 if contains @usableClasses, $_className;
  }
  return 0;
}
#-------------------------------------------------------------------------------
1;
