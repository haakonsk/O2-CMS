package O2CMS::Backend::Gui::Mail::Send;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($config);

#--------------------------------------------------------------------------------
sub init {
  my ($obj) = @_;
  $obj->showMailForm();
}
#--------------------------------------------------------------------------------
sub showMailForm {
  my ($obj) = @_;

  # Remove duplicates and empty email addresses
  my @recipients = split /,/, $obj->getParam('recipients');
  my %recipients = map  { $_ => 1 } @recipients;
  @recipients    = grep { $_      } keys %recipients;

  $obj->display(
    'showMailForm.html',
    recipients => join (',', @recipients),
    sender     => $obj->getParam('sender'),
  );
}
#--------------------------------------------------------------------------------
sub sendMail {
  my ($obj) = @_;
  require O2::Util::SendMail;
  my $smtpServer = $config->get('o2.smtp');
  my $sender = O2::Util::SendMail->new( smtp => $smtpServer );
  my %q = $obj->getParams();
  my $jsCode;
  my %sendParams = (
    to      => $q{to},
    from    => $q{from},
    subject => $q{subject},
    body    => $q{body},
  );
  if ($sender->send(%sendParams)) {
    $jsCode = "parent.mailSent();\n";
  }
  else {
    # XXX Shold we have error-handling when sending mail fails ?, bheltne
    $jsCode = "parent.mailSent();\n";
  }
  print "<html><body onload='init()'><script type=\"text/javascript\">function init() { $jsCode }</script></body></html>";
}
#--------------------------------------------------------------------------------
1;
