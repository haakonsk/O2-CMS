package O2CMS::Backend::Gui::System::Class;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#---------------------------------------------------------------------------------------
# Gives you a list of the class names this object can contain (if object is container)
sub getCanContainClasses {
  my ($obj) = @_;
  my %params = $obj->getParams();
  my $objectId = $params{objectId} or die 'objectId missing';
  
  my $object = $context->getObjectById($objectId) || $context->getSingleton('O2::Mgr::UniversalManager')->getTrashedObjectById($objectId) or die "Couldn't instantiate object with ID $objectId";
  die 'The given object (ID=$objectId) is not a container' unless $object->isContainer();
  
  my @canContainClasses = $context->getSingleton('O2::Mgr::ClassManager')->getCanContainClasses($object);
  return {
    classNames => \@canContainClasses,
  };
}
#---------------------------------------------------------------------------------------
1;
