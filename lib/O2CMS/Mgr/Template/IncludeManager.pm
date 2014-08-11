package O2CMS::Mgr::Template::IncludeManager;

use strict;

use base 'O2CMS::Mgr::Template::GridManager';

use O2CMS::Obj::Template::Include;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template::Include',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
sub queryIncludes {
  my ($obj, %params) = @_;
  $obj->queryGridsOrIncludes('Include', %params);
}
#-------------------------------------------------------------------------------
1;
