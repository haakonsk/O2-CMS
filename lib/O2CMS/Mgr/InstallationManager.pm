package O2CMS::Mgr::InstallationManager;
                                                                                                                                                                                 
use strict;

use base 'O2::Mgr::ContainerManager';

use O2CMS::Obj::Installation;
                                                                                                                                                                                 
#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Installation',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    version      => { type => 'varchar', length => 12, notNull => 1 },
    versionName  => { type => 'varchar', length => 32               },
    licenseModel => { type => 'varchar', length => 24               },
    licenseId    => { type => 'varchar', length => 32               },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
