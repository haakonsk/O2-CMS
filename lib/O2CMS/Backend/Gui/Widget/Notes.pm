package O2CMS::Backend::Gui::Widget::Notes;

# Desktop Widget Manager for O2 user desktops

use strict;

use base 'O2CMS::Backend::Gui::Widget';

use O2 qw($context $db);

#---------------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->display(
    'mainTemplate.html',
    notes => $obj->_getNotes(),
  );
}
#---------------------------------------------------------------------------------------
sub _getNotes {
  my ($obj) = @_;
  return [ $db->fetchAll( 'select noteId,note from O2CMS_WIDGET_NOTES where ownerId = ? order by noteId asc', $context->getUserId() ) ];
}
#---------------------------------------------------------------------------------------
sub saveNote {
  my ($obj) = @_;
  my $userId = $context->getUserId();
  my $noteId = $obj->getParam('noteId');
  my $note   = $obj->getParam('note');
  
  $note =~ s/\n/<br>/g;
  $note =~ s/"/\\"/g;
  $note =~ s/'/\\'/g;
  
  if ($noteId eq 'new') {
    $noteId = $db->idInsert(
      'O2CMS_WIDGET_NOTES',
      'noteId',
      note    => $note,
      ownerId => $userId,
    );
  }
  else {
    $db->sql( "update O2CMS_WIDGET_NOTES set note = ? where ownerId = ? and noteId = ?", $note, $userId, $noteId );
  }
  return {
    noteId => $noteId,
  };
}
#---------------------------------------------------------------------------------------
sub deleteNote {
  my ($obj) = @_;
  my $noteId = $obj->getParam('noteId');
  return 0 unless $noteId;
  
  $db->sql( "delete from O2CMS_WIDGET_NOTES where ownerId = ? and noteId = ?", $context->getUserId(), $noteId );
  return {
    noteId => $noteId,
  };
}
#---------------------------------------------------------------------------------------
1;
