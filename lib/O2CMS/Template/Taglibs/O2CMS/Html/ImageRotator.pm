package O2CMS::Template::Taglibs::O2CMS::Html::ImageRotator;

# We are using this one: http://www.jeroenwijering.com/?item=JW_Image_Rotator

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    ImageRotator  => 'postfix',
  );
  
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub ImageRotator {
  my ($obj, %params) = @_;

  $obj->{parser}->_parse( \$params{id} );
  $obj->{_playerId} = $params{id};

  $obj->{_uniquePlayerId} = 'ir_' . time . "_" . $$;
  
  $obj->{_images} = [];

  $obj->{parser}->pushMethod('addImage' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('addImage' => $obj);
  
  my $playListUrl = $obj->_writeXmlPlaylist( $params{staticPlaylist} ? 1 : 0 );

  my %defaultParams = (
    controlBackcolor => {
      name    => 'backcolor',
      default => '000000',
      prefix  => '0x'
    },
    controlFrontcolor => {
      name    => 'frontcolor',
      default => 'FFFFFF',
      prefix  => '0x'
    },
    controlLightcolor => {
      name    => 'lightcolor',
      default => 'C9C9C9',
      prefix  => '0x'
    },
    screencolor => {
      name    => 'screencolor',
      default => 'FFFFFF',
      prefix  => '0x'
    },
    height => {
      name    => 'height',
      default => '200',
    },
    width => {
      name    => 'width',
      default => '400',
    },
    logo =>  {
      name    => 'logo',
      default => '',#'/images/o2logo/o2_logo_47x22.gif',
    },
    scale => { 
      name    => 'overstretch',
      default => 'none', # scale, fit and none
    },
    transition => {
      name    => 'transition',
      default => 'random', # fade, bgfade, blocks, bubbles, circles, flash, fluids, lines or slowfade
    },
    autostart => {
      name    => 'autostart',
      default => 'true',
    },
    rotatetime => {
      name    => 'rotatetime',
      default => '5',
    },
    shuffle  =>  {
      name    => 'shuffle',
      default => 'false',
    }
  );

  my (@flashVars, $height, $width);
  foreach my $key (keys %defaultParams) {
    $height = $params{$key} || $defaultParams{$key}->{default} if $key eq 'height';
    $width  = $params{$key} || $defaultParams{$key}->{default} if $key eq 'width';
    if ( $params{$key} || $defaultParams{$key}->{default} ) {
      my $pf = $defaultParams{$key}->{prefix} || '';
      push @flashVars, $obj->{_uniquePlayerId} . '.addVariable("' . $defaultParams{$key}->{name} . '","' . $pf . ($params{$key} || $defaultParams{$key}->{default}) . '");';
    }
  }
  
  my $flashVars = join "\n", @flashVars;
  
  return qq|<div id="$obj->{_playerId}"><a href="http://www.macromedia.com/go/getflashplayer">Get the Flash Player</a> to see this rotator.</div>
<script type="text/javascript" src="/flash/imagerotator/swfobject.js"></script>
<script type="text/javascript">
  var $obj->{_uniquePlayerId} = new SWFObject("/flash/imagerotator/imagerotator.swf","rotator","$width","$height","7");
  $obj->{_uniquePlayerId}.addVariable("file","$playListUrl");
  $flashVars
  $obj->{_uniquePlayerId}.write("$obj->{_playerId}");
</script>
|;
}
#--------------------------------------------------------------------------------------------
sub _writeXmlPlaylist {
  my ($obj, $staticPlaylist) = @_;
  
  my $tracks = '';
  foreach my $item ( @{$obj->{_images}} ) {
    my $xml = '';
    foreach my $key ( keys %{$item} ) {
      $xml .= "<$key>$item->{$key}</$key>\n";
    }
    $tracks .= "<track>\n$xml</track>\n";
  }

  my $xml = qq|<?xml version="1.0" encoding="UTF-8"?> 
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <title></title>
  <info>http:/xspf.org/xspf-v1.html</info>
  <trackList>
    $tracks
  </trackList>
</playlist>|;

  my $path = $config->get('file.basePath') . '/imageRotator';
  my $url  = $config->get('file.baseUrl')  . '/imageRotator';
  
  # create the xml path
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->mkPath($path) unless -d $path;
  
  my $ct = time;
  # XXX We need a system to store new files and a system to delete after ttl has expired ala simplecache.
  my @files = $fileMgr->scanDir($path ,'.xml');
  foreach my $f (@files) {
    my @d = split /\_/, $f;
    next if $d[0] eq 'static';
    if ( $d[0] < $ct-(60) ) { # 1 min ttl
      unlink "$path/$f" if -e "$path/$f";
    }
  }
  
  my $file = '';
  if ($staticPlaylist) { # newer expire playlist
    $file = 'static_imagerotator_' . $obj->{_playerId} . '.xml';
  }
  else { # playlist will expires after 60seconds
    $file = $ct . '_imagerotator_' . $obj->{_playerId} . '_' . $$ . '.xml';
  }
  $fileMgr->writeFile($path . '/' . $file, $xml);
  return $url . '/' . $file;
}
#--------------------------------------------------------------------------------------------
sub addImage {
  my ($obj, %params) = @_;
 
  if ( $params{url} ) {
    push @{$obj->{_images}}, {
      location => $params{url},
      title => $obj->_fixChars($params{title}),
      info  => $params{info},
    };
  }
  return '';
}
#--------------------------------------------------------------------------------------------
sub _fixChars {
  my ($obj, $string) = @_;
   my %map = (
     # norway and å is used in sweden as well
     'Ø' => '&#216;',
     'Å' => '&#197;',
     'Æ' => '&#198;',
     'ø' => '&#248;',
     'å' => '&#229;',
     'æ' => '&#230;',
     # sweden
     'Ö' => '&#214;',
     'ö' => '&#246;',
     'ä' => '&#228;',
     'Ä' => '&#196;',
   );
  foreach my $c (keys %map) {
    $string =~ s/$c/$map{$c}/g;
  }
  return $string;
}
#--------------------------------------------------------------------------------------------
1;
__END__
<track>
  <title>Sunshine up Ahead</title>
  <creator>Peter Jones</creator>
  <location>http://www.jeroenwijering.com/upload/peterjones_sunshine_lofi.mp3</location>
  <info>http://www.peterjonesmusic.net/</info>
  <image>http://www.jeroenwijering.com/upload/peterjones.jpg</image>
</track>
