package O2CMS::Mgr::AdminUserManager;

use strict;

use base 'O2::Mgr::MemberManager';

use O2CMS::Obj::AdminUser;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::AdminUser',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub getUserByUsername {
  my ($obj, $username) = @_;
  return $obj->getMemberByUsername($username);
}
#-----------------------------------------------------------------------------
sub getUsers {
  my ($obj) = @_;
  return $obj->objectSearch();
}
#-----------------------------------------------------------------------------
1;
