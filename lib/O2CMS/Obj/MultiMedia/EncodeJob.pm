package O2CMS::Obj::MultiMedia::EncodeJob;

use strict;
use base 'O2::Obj::Object';

#-------------------------------------------------------------------------------
sub isDeletable {
  return 1;
}
#-------------------------------------------------------------------------------
sub isSerializable {
  return 0;
}
#-------------------------------------------------------------------------------
sub setEncodeParameters {
  my ($obj, %params) = @_;
  require O2::Data;
  my $data = O2::Data->new();
  $obj->setEncodeParametersPLDS( $data->dump(\%params) );
}
#-------------------------------------------------------------------------------
sub getEncodeParameters {
  my ($obj) = @_;
  require O2::Data;
  my $data = O2::Data->new();
  return %{  $data->undump( $obj->getEncodeParametersPLDS() )  };
}
#-------------------------------------------------------------------------------
sub appendEncoderLog {
  my ($obj, $log) = @_;
  my $currLog = $obj->getEncoderLog();
  $currLog   .= "\n" if $currLog;
  $obj->setEncoderLog($currLog . (scalar localtime) . ':' . $log);
}
#-------------------------------------------------------------------------------
1;
