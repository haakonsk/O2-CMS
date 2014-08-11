package O2CMS::Mgr::UrlManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Url;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Url',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    url        => { type => 'varchar'                    },
    title      => { type => 'varchar', multilingual => 1 },
    newWindow  => { type => 'int', validValues => [0, 1] },
    attributes => { type => 'text', listType => 'hash'   },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
1;
