package O2CMS::Mgr::Template::PageManager;

use strict;

use base 'O2CMS::Mgr::Template::GridManager';

use O2CMS::Obj::Template::Page;

#-------------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Template::Page',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title => { type => 'varchar', multilingual => 1 },
    #-----------------------------------------------------------------------------
  );
}
#-------------------------------------------------------------------------------
# Return all page templates
sub getPageTemplates {
  my ($obj) = @_;
  return grep  { -e $_->getFullPath() }  $obj->objectSearch();
}
#-------------------------------------------------------------------------------
1;
