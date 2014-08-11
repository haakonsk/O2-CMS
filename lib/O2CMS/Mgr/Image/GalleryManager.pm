package O2CMS::Mgr::Image::GalleryManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::Image::Gallery;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Image::Gallery',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title       => { type => 'varchar', multilingual => 1  }, # Do not use meta name, since that isn't multilingual
    description => { type => 'text', multilingual => 1     },
    imageIds    => { type => 'object', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
