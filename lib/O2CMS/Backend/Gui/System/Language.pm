package O2CMS::Backend::Gui::System::Language;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $config);

#---------------------------------------------------------------------------------
sub init { 
  my ($obj) = @_;
  my $resourcePath = sprintf '%s/var/resources', $context->getEnv('O2CUSTOMERROOT') || $config->get('o2.customerRootPath');
  if (!-d $resourcePath) {
    print "Could not locate a valid resourcePath: '$resourcePath'";
    return;
  }
  $obj->display(
    'languageTemplate.html', 
    treeMenu => $obj->getFiles($resourcePath),
  );
}
#---------------------------------------------------------------------------------
sub saveFile {
  my ($obj, %params) = @_;
  my $struct = $cgi->getStructure( $obj->getParam('path') );
  foreach my $field ($obj->getParam('newFields')) {
    next unless $field;
    my ($key, $value) = split /=/, $field, 2;
    if (!$key || !$value) {
      print "<li>$field: Wrong format<br></li>\n";
      next;
    }
    if ($key =~ m{ \s }xms) {
      print "<li>Not allowed to have white space in key ($key)</li>\n";
      next;
    }
    my @keyParts = split /\./, $key; # Key format: a.b.c
    my $hashRef = $struct;
    my $lastKeyPart = pop @keyParts;
    while (@keyParts) {
      my $keyPart = shift @keyParts;
      $hashRef->{$keyPart} = {} unless ref $hashRef->{$keyPart} eq 'HASH'; # Overwrites previous value if it wasn't a hash ref
      $hashRef = $hashRef->{$keyPart};
    }
    $hashRef->{$lastKeyPart} = $value;
  }
  my $version = $context->getSingleton('O2::Lang::I18NManager')->saveResourceFile( $obj->getParam('file'), $obj->_serializePlds($struct) );
  $obj->editFile(message => "File saved, current revision is $version!");
}
#---------------------------------------------------------------------------------
# List language variables alphabetically, so it will be easy to see the changes if subversion or another version control system is used
sub _serializePlds {
  my ($obj, $plds, $level) = @_;
  $level ||= 0;
  my $indent = '  ' x $level;
  my $content = "{\n";
  foreach my $key (sort keys %{$plds}) {
    my $value = $plds->{$key};
    if (ref $value eq 'HASH') {
      $content .= "  $indent'$key' => " . $obj->_serializePlds($value, $level+1);
      next;
    }
    die "Can't have array refs in language files" if ref $value eq 'ARRAY';
    $key   =~ s{ \' }{\\'}xmsg;
    $value =~ s{ \' }{\\'}xmsg;
    $content .= "  $indent'$key' => '$value',\n";
  }
  $content .= "$indent}";
  $content .= $indent ? ',' : ';';
  return "$content\n";
}
#---------------------------------------------------------------------------------
sub editFile {
  my ($obj, %params) = @_;

  my $i18nMgr = $context->getSingleton('O2::Lang::I18NManager');
  
  my $file         = $obj->getParam('file');
  my $resourcePath = sprintf '%s/var/resources', $context->getEnv('O2CUSTOMERROOT') || $config->get('o2.customerRootPath');

  my ($topPath) = $file =~ m{ / (\w+) [.] conf $ }xmsi;
  my $plds = $i18nMgr->getResourceFile($file);

  $obj->display(
    'editor.html', 
    plds    => $plds,
    topPath => $topPath,
    file    => $file,
    message => $params{message},
    path    => $topPath,
  );  
}
#---------------------------------------------------------------------------------
sub getFiles {
  my ($obj, $dir) = @_;
  $obj->{locale}  = $context->getLocale();
  my $tree = $obj->_recFiles($dir);
  return $tree;
}
#---------------------------------------------------------------------------------
sub _recFiles {
  my ($obj, $path, $level) = @_;
  
  my @files = $context->getSingleton('O2::File')->scanDir($path);
  my $treeStruct;
  $level ||= 0;
  my $space = '   ' x $level;

  foreach my $item (sort {lc($b) cmp lc($a)} @files) {

    next if $item=~m|^\.+|xms;
    if ($level == 0) {
      next unless $item=~m/^(?:\w\w\_\w\w|\w\w)$/i;
    }
    
    my ($territory,$language);
    if (length($item) == 5 && $item=~m/^(\w\w)\_(\w\w)$/) {
      $language  = $1;
      $territory = $2;
    }
    elsif (length($item) == 2 && $item=~m/^(\w\w)$/) {
      $language  = $1;
      $territory = $1;
    }
    else {
      next if $item =~ m{ [#~] }xms; # Don't show emacs backup files
    }

    my $langName = $language ? $obj->{locale}->getLanguageName(lc $language) : '';
    my $name     = $langName ? "$langName [$item]"                           : $item;
    $name        = sprintf "<img src='%s'>$name", $obj->{locale}->getTerritoryFlagSmallIconUrl(lc $territory) if $langName;
    my $isDir = -d "$path/$item" ? 1 : 0;

    if ($isDir && !$langName) {
      my $icon = '<img src="/images/system/foldr_16.gif">';
      $name = "$icon$name";
    }
    
    if ($isDir) {
      $name =~ s{ \" }{\\\"}xmsg;
      $treeStruct .= "$space<o2 TreeMenuFolder title=\"$name\">";
      $treeStruct .= $obj->_recFiles("$path/$item", $level+1);
      $treeStruct .= "$space</o2:TreeMenuFolder>\n";
    }
    else {
      my $icon = '<img src="/images/system/notep_16.gif" border=0>';
      my ($htmlName) = $name =~ m/([^\.]+)/;
      my $filePath= "$path/$item";
      my $url = '<o2 urlMod setMethod=editFile setParam=file=' . $cgi->urlEncode($filePath) . '/>';
      $treeStruct .= $space.'<o2 TreeMenuItem><a href="'.$url.'" target=editor>'.$icon.$htmlName.'</a></o2:TreeMenuItem>'."\n";
    }
  }
  return $treeStruct;
}
#---------------------------------------------------------------------------------
sub editKey {
  my ($obj) = @_;
  $obj->display(
    'editKey.html',
    keyId      => $obj->getParam('keyId'),
    localeCode => $obj->getParam('locale'),
  );
}
#---------------------------------------------------------------------------------
sub saveKey {
  my ($obj) = @_;
  my $resourcePath = sprintf '%s/var/resources', $obj->getEnv('O2CUSTOMERROOT') || $config->get('o2.customerRootPath');
  my @keyParts = split /\./, $obj->getParam('keyId');
  my $key = pop @keyParts;
  my $localePath = join '/', @keyParts;

  my $i18nMgr = $context->getSingleton('O2::Lang::I18NManager');

  my $text = $cgi->getStructure('text');
  foreach my $locale (keys %{$text}) {
    my $path = "$resourcePath/$locale/$localePath.conf";
    next unless $text->{$locale};
    if (!-e $path) {
      print "path does not exist";
      return;
    }
    my $plds = $i18nMgr->getResourceFile($path);
    $plds->{$key} = $text->{$locale};
    $i18nMgr->saveResourceFile( $path, $obj->_serializePlds($plds) );
  }
  print "<script>window.close()</script>";
}
#---------------------------------------------------------------------------------
1;
