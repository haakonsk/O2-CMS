package O2CMS::Mgr::Desktop::ShortcutManager;

use strict;

use base 'O2CMS::Mgr::Desktop::ItemManager';

use O2CMS::Obj::Desktop::Shortcut;

#--------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Desktop::Shortcut',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    action         => { type => 'varchar', length => 2048 },
    actionObjectId => { type => 'int', default => 0       },
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------
1;
