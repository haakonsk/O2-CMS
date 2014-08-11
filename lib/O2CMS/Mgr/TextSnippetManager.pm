package O2CMS::Mgr::TextSnippetManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2CMS::Obj::TextSnippet;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::TextSnippet',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    imageId     => { type => 'O2::Obj::Image' },
    textSnippet => { type => 'text'           },
    url         => { type => 'varchar'        },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
1;
