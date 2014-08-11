package O2CMS::Mgr::MultiMedia::EncodeJobManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $db);
use O2CMS::Obj::MultiMedia::EncodeJob;

#-----------------------------------------------------------------------------
sub getModelClassName {
  return 'O2CMS::Obj::MultiMedia::EncodeJob';
}
#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::MultiMedia::EncodeJob',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    sourceObjectId       => { type => 'int'                      },
    targetObjectId       => { type => 'int'                      },
    encodeStartTime      => { type => 'int'                      },
    encodeEndTime        => { type => 'int'                      },
    priority             => { type => 'int'                      },
    encodeModule         => { type => 'varchar', length => '255' },
    encodeHandler        => { type => 'varchar', length => '255' },
    encodeParametersPLDS => { type => 'text'                     },
    encoderLog           => { type => 'text'                     },
    callBackModule       => { type => 'varchar', length => '255' },
    callBackMethod       => { type => 'varchar', length => '255' },
    #-----------------------------------------------------------------------------
  );
  $obj->{debugMode} = 1;
}
#-----------------------------------------------------------------------------
sub encodeJobs {
  my ($obj, %params) = @_;
  
  my $addonSql = $params{ownerId} ? " and ownerId = $params{ownerId}" : '';
  my @jobIds = $db->fetchAll("select objectId from O2_OBJ_OBJECT where className = 'O2CMS::Obj::MultiMedia::EncodeJob' and status = 'new' $addonSql");
  
  my @encodedJobs;
  foreach my $job (@jobIds) {
    push @encodedJobs, $job->{objectId} if $obj->encodeJob( $job->{objectId} );
  }
  return 1;
}
#-----------------------------------------------------------------------------
sub encodeJob {
  my ($obj, $jobId) = @_;
  my $job = $context->getObjectById($jobId);
  return 1 if $job->getMetaStatus() eq 'encoded';

  $obj->_debug("Encoding job '" . $job->getMetaName() . "' [$jobId]");
  $job->setEncodeStartTime(time);
  $job->setMetaStatus('encoding');
  $job->save();
  
  my $encodeModule  = $job->getEncodeModule();
  my $encodeHandler = $job->getEncodeHandler();
  my %encodeParams  = $job->getEncodeParameters();
  
  eval  "require $encodeModule;";
  die __PACKAGE__." could not load encoder module : $encodeModule, reason $@" if $@;
  
  my $encoder;
  eval {
    $encoder = $encodeModule->new( encoder => $encodeHandler );
  };
  die __PACKAGE__." could not init encoder module : $encodeModule, reason $@" if $@;

  # do we have an O2 Object to encode from and to
  my $srcId = $job->getSourceObjectId();
  my $srcObj = $context->getObjectById($srcId);
  $encodeParams{inMedia} = $srcObj->getFilePath;
  # ok, lets do some encoding here
  $obj->_debug("-" x 100);
  my $resultFile = $encoder->encode(%encodeParams);
  $obj->_debug("-" x 100);
  if (!-e $resultFile) {
    die __PACKAGE__." something went wrong under the encoding of jobId $jobId, reason $@" if $@;
  }
  
  # is there specified a target O2 Object id to set the encoded result from?
  my $tarId = $job->getTargetObjectId();
  my $tarObj;
  $tarObj = $context->getObjectById($tarId) if $tarId;
  if (!$tarObj) {
    $tarObj = $context->getObjectById($srcId);
    $tarObj->setId(0);
  }
  
  # updating target file
  $tarObj->setMetaStatus('encoded');
  $tarObj->setContentFromPath($resultFile);
  $tarObj->save();
  $obj->_debug("OK error in2: |$@|");
  $job->setTargetObjectId( $tarObj->getId() );
  $job->setMetaStatus('encoded');
  $job->setEncodeEndTime(time);
  $job->save();
  $obj->_debug("OK error in3: $job|$@|");
  $obj->_executeCallbackMethod($job);# does this job defines a module to perform a callback to?
  $obj->_debug("OK error in4: |$@|");
  die __PACKAGE__." could not init source object, got source Id : $srcId, reason $@" if $@;
  return 1;
}

#-----------------------------------------------------------------------------
# performing a callback to the module that was set on the job
sub _executeCallbackMethod {
  my ($obj,$job)=@_;
  
  my $module = $job->getCallBackModule();
  my $method = $job->getCallBackMethod();
  return 1 unless $module && $method;
  
  my $cbObject;

  push @INC, $context->getEnv('O2CUSTOMERROOT') . '/lib'; # Just in case it isn't there already

  eval "require $module;";
  if ($@) {
    $job->appendEncoderLog("Could not load callBack module '$module', reason: $@");
    return 0;
  };
  eval {
    $cbObject = $module->new();
  };
  $job->appendEncoderLog("callBack Class didn't return a valid object,reason: $@") if ref $cbObject ne $module;
  $obj->_debug("executing callback method '$module->$method'");
  eval {
    $cbObject->$method($job);
  };
  $job->appendEncoderLog("Could not call '$method' in '$module', reason: $@") if $@;
  return 1;
}
#-----------------------------------------------------------------------------
sub _debug {
  my ($obj, $m) = @_;
  print scalar localtime (time) . ":$m\n" if $obj->{debugMode};
}
#-----------------------------------------------------------------------------
1;
__END__

Notes:

sourceObjectId  => O2_OBJ_OBJECT ID to encode from
targetObjectId  => O2_OBJ_OBJECT ID to save the encoded file to
encodeStartTime => epoch start time
encodeEndTime   => epoch when it was finish
priority        => job priority, not implementeted 1 is hightest
encodeModule    => module to encode with <- must be a O2 compliant module
encodeHandler   => what encode to use (E.g SOX, mencoder, ffmpeg etc..)
encodeParameter => datastruct to with encoder parameters,
callBackModule  => callback module <- must be a O2 compliant module
callBackMethod  => method to perl form a callback to when encoding is done (job objectId will be supplied as parameter) 

alter table O2CMS_OBJ_MULTIMEDIA_ENCODEJOB add encodeHandler varchar(255) default '';
