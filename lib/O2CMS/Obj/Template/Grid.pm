package O2CMS::Obj::Template::Grid;

use strict;

use base 'O2CMS::Obj::Template';

use O2 qw($context);
use O2CMS::Obj::Template::SlotList;

#-------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  my $slotMgr = $context->getSingleton('O2CMS::Mgr::Template::SlotManager');
  $obj->{slotList} = $slotMgr->newSlotList();
  return $obj;
}
#-------------------------------------------------------------------------------
sub setSlotList {
  my ($obj, $slotList) = @_;
  $obj->{slotList} = $slotList;
}
#-------------------------------------------------------------------------------
sub getSlotList {
  my ($obj) = @_;
  return $obj->{slotList};
}
#-------------------------------------------------------------------------------
sub getSlotById {
  my ($obj, $slotId) = @_;
  return $obj->getSlotList()->getSlotById($slotId);
}
#-------------------------------------------------------------------------------
sub asString {
  my ($obj, $asHtml) = @_;
  my $str = '';
  $str   .= $obj->getMetaClassName() . '/' . $obj->getId() . "\n";
  $str   .= 'path: ' . $obj->getPath() . "\n";
  $str   .= $obj->{slotList}->asString($asHtml);
  return $str;
}
#-------------------------------------------------------------------------------
sub getContentPlds {
  my ($obj) = @_;
  my $data = $obj->SUPER::getContentPlds();
  $data->{slotList} = $obj->{slotList}->serialize();
  return $data;
}
#-------------------------------------------------------------------------------
sub setContentPlds {
  my ($obj, $plds) = @_;
    
  if ($obj->verifyContentPlds($plds)) {
    $obj->{slotList}->unserialize( delete $plds->{slotList} );
    return $obj->SUPER::setContentPlds($plds);
  }
  else {
    die "ContentPLDS could not be verified: $@";
  }
  return 1;
}
#-------------------------------------------------------------------------------
1;
