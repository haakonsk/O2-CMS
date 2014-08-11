package O2CMS::Mgr::TerritoryManager;

use strict;

use base 'O2::Mgr::ContainerManager';

use O2 qw($context $db);
use O2CMS::Obj::Territory;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Territory',
    code     => { type => 'varchar' },
    codePath => { type => 'varchar' },
  );
}
#-----------------------------------------------------------------------------
# classNames
# codePath
# code
sub queryTerritories {
  my ($obj, %args) = @_;
  
  my @from = ('O2CMS_OBJ_TERRITORY t');
  my @where;
  my @placeholders;
  
  if ( $args{classNames} ) {
    push @from, 'O2_OBJ_OBJECT o';
    push @where, 'o.objectId=t.objectId';
    push @where, 'o.className in ('.join(',', map '?', @{$args{classNames}}).')';
    push @placeholders, @{$args{classNames}};
  }
  
  if ( $args{codePath} ) {
    push @where, $args{codePath} =~ /\%/ ? 'codePath like ?' : 'codePath=?';
    push @placeholders, $args{codePath};
  }
  if ( $args{code} ) {
    push @where, 'code=?';
    push @placeholders, $args{code};
  }
  
  my $sql = 'select t.objectId from ' . join ',', @from;
  $sql   .= ' where ' . join (' and ', @where) if @where;
  my @ids = $db->selectColumn($sql, @placeholders);
  return $context->getObjectsByIds(@ids);
}
#-----------------------------------------------------------------------------
1;
