package O2CMS::Frontend::Gui::Mail::Form;

# Mail any form to given e-mail address(es), use a template to format the mail
# needs a "mailAFormId" as key to find correct mailtemplate and receiver. This for security

use strict;

use base 'O2::Gui';

use O2 qw($config $cgi);

#-----------------------------------------------------------------------------
sub mailForm {
  my $obj = @_;
  
  my $mailAFormId = $obj->getParam('mailAFormId');

  die "Need an O2 Mail a form Id" unless $mailAFormId;

  my %mailAForm = $config->getHash('mailAForm.'.$mailAFormId);
  
  die "Invalid O2 Mail a form Id" unless scalar keys %mailAForm;
  
  my $fromAddress  = $obj->getParam('senderEmail') =~ m{ \@ }xms ? $obj->getParam('senderEmail') : ($mailAForm{senderEmail} || $config->get('o2.defaultFromEmail') );
  my $toAddress    = $mailAForm{receiverEmail};
  my $subject      = $obj->getParam('subject')  || $mailAForm{subject};
  my $templateFile = $obj->getParam('template') || $mailAForm{mailTemplate};
  
  $cgi->setParam('isAjaxRequest', undef);
  my $body = $obj->display(
    $templateFile,
    $obj->getParams(),
    __doNotPrint => 1,
  );
  $cgi->setParam('isAjaxRequest', 1);

  require O2::Util::SendMail;
  my $mailer = O2::Util::SendMail->new();
  $mailer->send(
    to      => $toAddress,
    from    => $fromAddress,
    subject => $subject,
    body    => $body,
    html    => 1,
  );

  return 1;
}
#-----------------------------------------------------------------------------
1;
