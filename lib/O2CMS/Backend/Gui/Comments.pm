package O2CMS::Backend::Gui::Comments;

use strict;

use base 'O2CMS::Backend::Gui';
use base 'O2::Gui::Comments';

use O2 qw($context $cgi);

#------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  my ($totalNumComments) = $context->getSingleton('O2::Mgr::CommentManager')->search()->getCount();
  $obj->display(
    'init.html',
    gui              => $obj,
    totalNumComments => $totalNumComments,
  );
}
#------------------------------------------------------------------
sub getComments {
  my ($obj, $skip, $limit) = @_;
  return $context->getSingleton('O2::Mgr::CommentManager')->objectSearch(
    -orderBy => 'objectId desc',
    -skip    => $skip,
    -limit   => $limit,
  );
}
#------------------------------------------------------------------
sub deleteComment {
  my ($obj) = @_;
  my $comment = $context->getObjectById( $obj->getParam('commentId') );
  $comment->delete();
  return 1;
}
#------------------------------------------------------------------
sub showReplyForm {
  my ($obj) = @_;
  my $comment = $context->getObjectById( $obj->getParam('commentId') );
  $obj->display(
    "showReplyForm.html",
    comment => $comment,
  );
}
#------------------------------------------------------------------
sub saveReply {
  my ($obj) = @_;
  my $reply = $obj->_getCommentObjectFromRequest( $obj->getParam('commentId') );
  $reply->setMetaParentId( $obj->getParam('commentId') );
  $reply->save();
  $cgi->redirect(
    setMethod => 'init',
  );
}
#------------------------------------------------------------------
1;
