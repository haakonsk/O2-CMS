package O2CMS::Obj::Message;

# metaStatus holds information about whether the message is sent/read/archived

use strict;
use base 'O2::Obj::Object';

#--------------------------------------------------------------------------------------------------
sub reply {
  my ($obj) = @_;

  die "Cannot reply to a message that isn't sent!" if !$obj->isSent() || !$obj->getId();

  my $newMessage = $obj->getManager()->newObject();
  $newMessage->setMetaParentId( $obj->getId()                                                                 );
  $newMessage->setSubject(      $obj->getSubject() =~ m/Re:/ ? $obj->getSubject() : 'Re:'. $obj->getSubject() );
  $newMessage->setSenderId(     $obj->getReceiverId()                                                         );
  $newMessage->setReceiverId(   $obj->getSenderId()                                                           );
  return $newMessage;
}
#--------------------------------------------------------------------------------------------------
sub setSubject {
  my ($obj, $subject) = @_;
  $obj->setMetaName($subject);
  $obj->setModelValue('subject', $subject);
}
#--------------------------------------------------------------------------------------------------
sub getQuotedBody {
  my ($obj) = @_;
  my $body = $obj->getBody();
  $body    =~ s/^/> /mg;
  return $body;
}
#--------------------------------------------------------------------------------------------------
sub send {
  my ($obj) = @_;
  die "Message already sent" if $obj->isSent();

  $obj->setSentDateTime( time );
  $obj->setIsSent(       1    );
  $obj->save();
}
#--------------------------------------------------------------------------------------------------
sub setIsRead {
  my ($obj) = @_;
  $obj->setMetaStatus('read');
}
#--------------------------------------------------------------------------------------------------
sub isRead {
  my ($obj) = @_;
  return $obj->getMetaStatus() eq 'read';
}
#--------------------------------------------------------------------------------------------------
sub setIsSent {
  my ($obj) = @_;
  $obj->setMetaStatus('sent');
}
#--------------------------------------------------------------------------------------------------
sub isSent {
  my ($obj) = @_;
  return $obj->isRead() || $obj->getMetaStatus() eq 'sent';
}
#--------------------------------------------------------------------------------------------------
sub setIsArchived {
  my ($obj) = @_;
  $obj->setMetaStatus('archived');
}
#--------------------------------------------------------------------------------------------------
sub isArchived {
  my ($obj) = @_;
  return $obj->getMetaStatus() eq 'archived';
}
#--------------------------------------------------------------------------------------------------
1;
