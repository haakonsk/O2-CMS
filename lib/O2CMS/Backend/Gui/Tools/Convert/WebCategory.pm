package O2CMS::Backend::Gui::Tools::Convert::WebCategory;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $db);

#---------------------------------------------------------------------------------------
sub convertCategories {
  my ($obj, %params) = @_;

  my @categories = $db->fetchAll('select * from O2CMS_OBJ_CATEGORY');
  foreach my $category (@categories) {
    next unless $category->{directoryName};
    my ($className) = $db->fetch( 'select className  from O2_OBJ_OBJECT where objectId=?', $category->{objectId} );
    print "$className - $category->{objectId} $category->{directoryName}";

    my ($hasWebCategory) = $db->fetch( 'select 1 from O2CMS_OBJ_WEBCATEGORY where objectId=?', $category->{objectId} );
    if( $className eq 'O2CMS::Obj::Category' && !$hasWebCategory) {
      print " [Upgrading to WebCategory]";
      # upgrade Category to WebCategory
      $db->sql("update O2_OBJ_OBJECT set className='O2CMS::Obj::WebCategory' where objectId=$category->{objectId}");
      $db->sql("insert into O2CMS_OBJ_WEBCATEGORY (objectId, directoryName) values ($category->{objectId},'$category->{directoryName}')");
    }
    print "<br>";
  }
}
#---------------------------------------------------------------------------------------
1;
