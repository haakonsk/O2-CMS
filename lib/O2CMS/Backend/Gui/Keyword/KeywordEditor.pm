package O2CMS::Backend::Gui::Keyword::KeywordEditor;

use strict;

use base 'O2CMS::Backend::Gui';

use constant DEBUG => 0;
use O2 qw($context $cgi);

#-----------------------------------------------------------------------------------------
sub init {
  my ($obj, %params) = @_;
  
  my $objectId = $obj->getParam('objectId');
  my $object;
  $object = $context->getObjectById($objectId) if $objectId;
  
  my $kwMgr = $context->getSingleton('O2::Mgr::KeywordManager');
  my $keywordFolders = $kwMgr->getKeywordWithChilds();
  $obj->display(
    'init.html',
    object         => $object,
    keywordFolders => $keywordFolders,
  );
}
#-----------------------------------------------------------------------------------------
sub searchKeywords {
  my ($obj) = @_;
  my $kwMgr = $context->getSingleton('O2::Mgr::KeywordManager');
  my @data = $kwMgr->getObjectsByNameMatch( $obj->getParam('keyword') );
  my @jsData;
  foreach (@data) {
    push @jsData, {
      id    => $_->getId(),
      value => $_->getMetaName(),
      path  => $_->getFullName(),
    };
  }
  @jsData = sort { lc ( $a->{value} ) cmp lc ( $b->{value} ) } @jsData;
  return {
    keywords => \@jsData,
  };
}
#-----------------------------------------------------------------------------------------
sub addKeywordIdToObjectId {
  my ($obj) = @_;
  my $objectId  = $obj->getParam('objectId');
  my $keywordId = $obj->getParam('keywordId');
  
  my $object = $context->getObjectById($objectId);
  $object->addKeywordById($keywordId);
  $object->save();
  return 1;
}
#-----------------------------------------------------------------------------------------
sub delKeywordIdFromObjectId {
  my ($obj) = @_;
  my $objectId  = $obj->getParam('objectId');
  my $keywordId = $obj->getParam('keywordId');
  
  my $object = $context->getObjectById($objectId);
  $object->delKeywordById($keywordId);
  $object->save();
  return 1;
}
#-----------------------------------------------------------------------------------------
sub getKeywordsByObjectId {
  my ($obj) = @_;
  my $objectId = $obj->getParam('objectId');
  my $object = $context->getObjectById($objectId);
  my @keywords = $object->getKeywords();
  my @jsData;
  foreach (@keywords) {
    push @jsData, {
      id    => $_->getId(),
      value => $_->getMetaName(),
      path  => $_->getFullName(),
    };
  }
  @jsData = sort { lc ( $a->{value} ) cmp lc ( $b->{value} ) } @jsData;
  return {
    keywords => \@jsData,
  };
}
#-----------------------------------------------------------------------------------------
sub getChildrenByObjectId {
  my ($obj) = @_;
  my $objectId = $obj->getParam('objectId');
  my $object = $context->getObjectById($objectId);
  my @jsData;
  foreach ($object->getChildren()) {
    if ( $_->getMetaName() ) {
      push @jsData, {
        id    => $_->getId(),
        value => $_->getMetaName(),
        path  => $_->getFullName(),
      };
    }
  }
  return {
    keywords => \@jsData,
  };
}
#-----------------------------------------------------------------------------------------
sub addKeywordInFolder {
  my ($obj) = @_;
  my $kwMgr = $context->getSingleton('O2::Mgr::KeywordManager');
  my $newKeyword = $kwMgr->newObject();
  $newKeyword->setMetaName(     $obj->getParam('keyword')  );
  $newKeyword->setMetaParentId( $obj->getParam('parentId') );
  $newKeyword->save();
  return {
    keyword => {
      id    => $newKeyword->getId(),
      value => $newKeyword->getMetaName(),
      path  => $newKeyword->getFullName(),
    }
  };
}
#-----------------------------------------------------------------------------------------
sub test {
  my ($obj) = @_;
  my $objectId  = $obj->getParam('objectId');
  my $object = $context->getObjectById($objectId);
  $object->setKeywordIds();
  $object->save();
  my $d = $context->getSingleton('O2::Data');
  print $d->dump($object->getObjectPlds);
  print "hm:".$object->getKeywordIds();
}
#-----------------------------------------------------------------------------------------
sub edit {
  my ($obj) = @_;
  $obj->display(
    'edit.html',
    object => undef,
  );
}
#-----------------------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  use Data::Dumper;
  my $keywords = $cgi->getStructure('object.keywordIds');
  print Dumper($keywords);
}
#-----------------------------------------------------------------------------------------
sub getFolderKeywords {
  my ($obj) = @_;
  return {
    folderKeywords => [ $obj->_getFolderKeywords() ],
  };
}
#-----------------------------------------------------------------------------------------
# lookup matching keywords, return best match along with alternatives
sub queryKeywords {
  my ($obj) = @_;
  my %params = $obj->getParams();
  
  # find matching keywords
  my $keywordMgr = $context->getSingleton('O2::Mgr::KeywordManager');
  $params{keyword} =~ s|^\s+||;
  $params{keyword} =~ s|\s+$||;
  my ($nameMatch) = $params{keyword} =~ /^(.{1,3})/;
  my @keywords = $keywordMgr->getObjectsByNameMatch("$nameMatch*");
  
  my @alternativeKeywords;
  # do we have a perfect match?
  my ($perfectMatch) = grep { lc ( $_->getMetaName() ) eq lc ( $params{keyword} ) } @keywords;
  if ($perfectMatch) {
    debug 'perfectMatch: ' . $perfectMatch->getFullName();
    @alternativeKeywords = ( { id => $perfectMatch->getId(), name => $perfectMatch->getFullName() } );
  }
  else {
    # add keyword immediately if keyword not found and we want to add folder
    if ( $params{addFolder} ) {
      debug 'Add and save keyword';
      my $keyword = $keywordMgr->newObject();
      $keyword->setMetaName(     $params{keyword}  );
      $keyword->setMetaParentId( $params{parentId} );
      $keyword->setIsFolder(     1                 );
      $keyword->save();
      @alternativeKeywords = ( { id => $keyword->getId(), name => $keyword->getFullName() } );
    }
    else {
      debug 'List alternatives';
      # present list of alternatives
      @alternativeKeywords = map { { name => $_->getFullName(), id => $_->getId() } } @keywords;
      @alternativeKeywords = sort { $a->{name} cmp $b->{name} } @alternativeKeywords;
      # include original keyword
      my $name = $params{keyword};
      if ( $params{parentId} > 0 ) {
        my $keyword = $keywordMgr->newObject();
        $keyword->setMetaName(     $params{keyword}  );
        $keyword->setMetaParentId( $params{parentId} );
        $name = $keyword->getFullName();
      }
      unshift @alternativeKeywords, {
        name => $name,
        id   => "$params{parentId}_$params{keyword}",
      };
    }
  }
  
  return {
    ix                  => $params{ix},
    alternativeKeywords => \@alternativeKeywords,
    folderKeywords      => [ $obj->_getFolderKeywords() ],
  };
}
#-----------------------------------------------------------------------------------------
sub _getFolderKeywords {
  my ($obj) = @_;
  my @keywords = $context->getSingleton('O2::Mgr::KeywordManager')->getFolderKeywords();
  my @options = map  { { name => $_->getFullName(), id => $_->getId() } } @keywords;
  @options    = sort { $a->{name} cmp $b->{name} } @options;
  unshift @options, { name => '/', id => undef };
  return @options;
}
#-----------------------------------------------------------------------------------------
1;

__END__

File under
[Hierarki][Roger    ][Remove]

<input onchange="findMatching(ix, this.value)">

Keywords
[Tor     ] [^Alternatives]
[London  ]
[Turist  ]
Save

[Tor     ] Kjent: /Personer/Venner/Tor
[London  ] Kjent: /Steder/England/London
[Turist  ]

Operations:
Use existing
Add flat
Add to hierarchy
Delete from object
Delete keyword from db

Bruteforce:

[^parent]  [name   ] [alternatives]
/
/Personer/ [Family]

- Oslo [-]
- [organize] [^Tor|Torsdag] [-]

Keyword [      ] [Add]
