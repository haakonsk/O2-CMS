package O2CMS::Backend::Gui::Build;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context);

#-----------------------------------------------------------------------------------------
sub addClass {
  my ($obj, $class) = @_;
  $class=~ s!.+lib/O2!O2!;
  $class=~ s!/!::!g;
  $class=~ s!\.pm$!!;
  push @{ $obj->{classes} }, $class;
}
#-----------------------------------------------------------------------------------------
sub scan {
  my ($obj, $dir) = @_;
  my @files = eval { $context->getSingleton('O2::File')->scanDir($dir, '^[^.]') };
  foreach my $fileName (@files) {
    my $path = "$dir/$fileName";
    if (-d $path) {
      $obj->scan($path);
    }
    else {
      next if $fileName !~ m/\.pm$/;
      $obj->addClass($path);
    }
  }
}
#-----------------------------------------------------------------------------------------
1;
