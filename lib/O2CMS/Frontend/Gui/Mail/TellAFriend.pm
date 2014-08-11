package O2CMS::Frontend::Gui::Mail::TellAFriend;

use strict;

use base 'O2::Gui';

use O2 qw($config $cgi);

#-----------------------------------------------------------------------------
sub tell {
  my ($obj) = @_;
  eval {
    $cgi->setParam('isAjaxRequest', undef);
    my $body = $obj->display(
      'mail.html',
      title        => $obj->getParam('title')       || '',
      url          => $obj->getParam('url')         || '',
      email        => $obj->getParam('senderEmail') || '',
      comment      => $obj->getParam('comment')     || '',
      __doNotPrint => 1,
    );
    $cgi->setParam('isAjaxRequest', 1);
    require O2::Util::SendMail;
    my $mailer = O2::Util::SendMail->new();
    my $fromAddress   =   $obj->getParam('senderEmail') =~ m{ \@ }xms   ?   $obj->getParam('senderEmail')   :   $config->get('o2.defaultFromEmail');
    $mailer->send(
      to      => $obj->getParam('recipientEmail'),
      from    => $fromAddress,
      subject => $obj->getLang()->getString('grids.tellAFriend.mailSubject'),
      body    => $body,
      html    => 1,
    );
  };
  if ($@) {
    $obj->error($@);
  }
  return 1;
}
#-----------------------------------------------------------------------------
1;
