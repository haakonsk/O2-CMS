package O2CMS::Template::Taglibs::O2CMS::Publisher;

use strict;

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  my $obj = bless \%params, $package;

  $obj->{pageRenderer} = $params{parser}->getProperty('pageRenderer');

  my %methods = (
    objectUrl  => 'postfix',
    ifBackend  => 'postfix',
    ifFrontend => 'postfix',
  );
  return $obj, %methods;
}
#-----------------------------------------------------------------------------
sub objectUrl {
  my ($obj, %params) = @_;

  my %urlParams = ( absolute => $params{absolute} );
  $obj->{parser}->parseVars( \$params{objectId} );
  my $object = $context->getObjectById( $params{objectId} );

  # force objectPath
  if ($params{path}) {
    $obj->{parser}->parseVars( \$params{path} );
    $urlParams{objectPath} = $params{path};
  }

  return eval {
    # if the object is a file, we should link directly to that file instead of...
    return $object->getFileUrl() if $object->isa('O2::Obj::File');
    
    # ...the o2 object url
    return $object->getDefaultUrl(%urlParams);
  } || undef;
}
#-----------------------------------------------------------------------------
# render content of tag only in frontend
sub ifFrontend {
  my ($obj, %params) = @_;
  if ( !$obj->{pageRenderer}  ||  $obj->{pageRenderer}->getMediaName() eq 'Html' ) {
    $obj->{parser}->_parse(\$params{content});
    return $params{content};
  }
  return '';
}
#-----------------------------------------------------------------------------
# render content of tag only in backend
sub ifBackend {
  my ($obj, %params) = @_;
  return '' unless $obj->{pageRenderer};
  return '' unless $obj->{pageRenderer}->getMediaName() eq 'Editor';
  $obj->{parser}->_parse( \$params{content} );
  return $params{content};
}
#-----------------------------------------------------------------------------
1;
