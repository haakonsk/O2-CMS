package O2CMS::Backend::Gui::System::ClassIconManager;

# Developer tool to administrate O2 classIcons

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $config);

#---------------------------------------------------------------------------------
sub init { 
  my ($obj) = @_;
  $obj->display(
    'mainTemplate.html',
    classNames => [ $context->getSingleton('O2::Mgr::ClassManager')->getClassNames() ],
  );
}
#---------------------------------------------------------------------------------
sub saveIcons {
  my ($obj)=shift;
  my $o2ClassIconsPath   = $config->get('o2.root').'/var/www/images/system/classIcons';
  my $custClassIconsPath = $config->get('o2.customerRootPath').'/var/www/images/system/classIcons';
  print "<li>$o2ClassIconsPath :"   . (-w $o2ClassIconsPath   ? 'can write' : 'can not write');
  print "<li>$custClassIconsPath :" . (-w $custClassIconsPath ? 'can write' : 'can not write');
  my %q = $obj->getParams();
  foreach (keys %q) {
    my ($className, $size) = $_ =~ m/^(.+)::(\d+)$/xms;
    next if !$className || !$size;
    my $fileName = $_;
    my $cgiFile  = $q{$_};
    next unless $cgiFile->getFileSize();
    $fileName =~ s/::/-/gxms;
    $fileName =~ s/\-16//gxms;
    print "<li>Saving <b>$className</b> size <b>$size</b> to <b>$fileName.gif</b>";

    if ($className =~ m/^O2\:\:.+/xms && -w $o2ClassIconsPath) {
      eval {
        $cgiFile->storeFile("$o2ClassIconsPath/$fileName.gif");
      };
      if ($@) {
        print "<br><font color='red'>&nbsp;&nbsp;Could not save it to <b>$o2ClassIconsPath/$fileName.gif</b></font>";
      }
      else {
        print "<br><font color='green'>&nbsp;&nbsp;Saved it to <b>$o2ClassIconsPath/$fileName.gif</b></font>";
      }
    }
    else {
      eval {
        $cgiFile->storeFile("$custClassIconsPath/$fileName.gif");
      };
      if ($@) {
        print "<br><font color='red'>&nbsp;&nbsp;Could not save it to <b>$custClassIconsPath/$fileName.gif</b></font>";
      }
      else {
        print "<br><font color='green'>&nbsp;&nbsp;Saved it to <b>$custClassIconsPath/$fileName.gif</b></font>";
      }
    }
  }
  print "<a href='/o2cms/System-ClassIconManager/'>[ click here go back to overview ]</a>";
}
#---------------------------------------------------------------------------------
1;
