use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2::Script::Common;

use O2 qw($context $db);
my %objectIds     = map { $_ => 1 } $db->selectColumn("select removedObjectId from O2CMS_OBJ_TRASHCAN_CONTENT");
my @idsWithParent =                 $db->selectColumn("select objectId from O2_OBJ_OBJECT where parentId is not null");
foreach my $id (@idsWithParent) {
  delete $objectIds{$id};
}
my @objectIds = keys %objectIds; # All @objectIds point to objects without parent

# Delete 10 000 rows at a time
while (@objectIds) {
  warn scalar @objectIds;
  my @ids = splice @objectIds, 0, (@objectIds > 10_000 ? 10_000 : scalar @objectIds);
  $db->do("delete from O2CMS_OBJ_TRASHCAN_CONTENT where removedObjectId in (??)", \@ids);
}
