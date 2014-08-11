#!/local/bin/perl

package O2CMS::Backend::Dispatch::mod_perl;

# mod_perl dispatcher for O2

use strict;

use O2::Cgi;
use O2::Cgi::Statuscodes;

#------------------------------------------------------------------
sub handler {
  my $cgi = O2::Cgi->new();

  eval {
    require O2CMS::Backend::Dispatch;
    O2CMS::Backend::Dispatch::dispatch($cgi);
  };

  if ($@) {
    my $r = shift;
    require O2::Cgi::FatalsToBrowser;
    $r->print( O2::Cgi::FatalsToBrowser::html(undef, "Application error: $@") );
  }

  $cgi->output(); # XXX Should probably be somewhere else..

  return getStatus( $cgi->getStatus() );
}
#------------------------------------------------------------------
1;
