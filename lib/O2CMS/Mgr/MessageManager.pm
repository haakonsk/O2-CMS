package O2CMS::Mgr::MessageManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Message;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Message',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    sender             => { type => 'O2::Obj::Person', notNull => 1          },
    body               => { type => 'mediumtext'                             }, # Bodypart of message
    subject            => { type => 'varchar', size => '255', notNull => '1' }, # Subject part of message
    attachments        => { type => 'object', listType => 'array'            }, # Array of attachhment objects, could be anything - article, image - report
    receiver           => { type => 'O2::Obj::Person'                        },
    isHiddenFromSender => { type => 'bit', defaultValue => '0'               }, # Only the receiver will see this message 
    #-----------------------------------------------------------------------------
  );
  $model->registerIndexes(
    'O2CMS::Obj::Message',
    { name => 'senderIndex',   columns => [qw(sender)],   isUnique => 0 },
    { name => 'receiverIndex', columns => [qw(receiver)], isUnique => 0 },
  );
}
#-----------------------------------------------------------------------------
sub getNumUnreadMessagesFor {
  my ($obj, $user) = @_;
  my @ids = $obj->objectIdSearch(
    receiver   => $user->getId(),
    metaStatus => 'sent',
  );
  return scalar @ids;
}
#--------------------------------------------------------------------------------------------------
sub getNumSentMessagesFor {
  my ($obj, $user) = @_;
  my @ids = $obj->objectIdSearch(
    sender             => $user->getId(),
    isHiddenFromSender => 0,
  );
  return scalar @ids;
}
#--------------------------------------------------------------------------------------------------
sub getUnreadMessagesFor {
  my ($obj, $user, $skip, $limit, %params) = @_;
  $params{-skip}  = $skip  if $skip;
  $params{-limit} = $limit if $limit;
  return $obj->objectSearch(
    receiver   => $user->getId(),
    metaStatus => 'sent',
    %params,
  );
}
#-----------------------------------------------------------------------------
sub getReadAndUnreadMessagesFor {
  my ($obj, $user, $skip, $limit, %params) = @_;
  $params{-skip}  = $skip  if $skip;
  $params{-limit} = $limit if $limit;
  return $obj->objectSearch(
    receiver   => $user->getId(),
    metaStatus => { in => [qw(read sent)] },
    %params,
  );
}
#-----------------------------------------------------------------------------
sub getSentMessagesFor {
  my ($obj, $user, $skip, $limit, %params) = @_;
  $params{-skip}  = $skip  if $skip;
  $params{-limit} = $limit if $limit;
  return $obj->objectSearch(
    sender             => $user->getId(),
    isHiddenFromSender => 0,
    %params,
  );
}
#--------------------------------------------------------------------------------------------------
1;
