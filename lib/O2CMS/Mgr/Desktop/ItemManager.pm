package O2CMS::Mgr::Desktop::ItemManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Desktop::Item;

#--------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Desktop::Item',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    imageUrl    => { type => 'varchar', length => 255 }, # using image since iconUrl is reserved in O2::Obj::Object
    description => { type => 'varchar', length => 255 },
    xPosition   => { type => 'int', defaultValue => 0 },
    yPosition   => { type => 'int', defaultValue => 0 },
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------
1;
