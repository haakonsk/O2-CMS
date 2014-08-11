package O2CMS::Backend::Gui::System::Search;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $session);

#-----------------------------------------------------------------------------
sub edit {
  my ($obj, $searchResultObjects) = @_;
  
  my ($query, @results) = $obj->_getQueryObjectAndResults();
  
  $obj->display(
    'edit.html',
    query   => $query,
    id      => $query ? $query->getId()       : undef,
    name    => $query ? $query->getMetaName() : undef,
    gui     => $obj,
    results => \@results,
  );
}
#-----------------------------------------------------------------------------
sub search {
  my ($obj) = @_;
  
  my ($query, @results) = $obj->_getQueryObjectAndResults();
  
  $obj->display(
    'includes/searchResults.html',
    results => \@results,
  );
}
#-----------------------------------------------------------------------------
sub addSearchCriterion {
  my ($obj) = @_;
  my $type = $obj->getParam('criterionName');
  $obj->display(
    'includes/searchForm/criterion.html',
    criterionName => $type,
    gui           => $obj,
  );
}
#-----------------------------------------------------------------------------
sub _callMethod {
  my ($obj, $method) = @_;
  return $obj->$method();
}
#-----------------------------------------------------------------------------
sub _getAvailableUsers {
  my ($obj) = @_;
  my @users = $context->getSingleton('O2CMS::Mgr::AdminUserManager')->objectSearch();
  @users    = map  { { name => $_->getMetaName(), value => $_->getId() } }  @users;
  @users    = sort { lc ( $a->{name} )  cmp  lc ( $b->{name} )           }  @users;
  return \@users;
}
#-----------------------------------------------------------------------------
sub _getAvailableClasses {
  my ($obj) = @_;
  my @classes;
  
  my $classMgr = $context->getSingleton('O2::Mgr::ClassManager');
  my $lang = $obj->getLang();
  
  foreach my $className ($classMgr->getClassNames()) {
    my $class = $classMgr->getObjectByClassName($className);
    my $name  = $lang->getClassname($className);
    push @classes, {
      name  => $name,
      value => $className,
    } if $name !~ m{ [<>] }xms;
  }
  @classes = sort { $a->{name} cmp $b->{name} } @classes;
  return \@classes;
}
#-----------------------------------------------------------------------------
sub _getAvailableCategories {
  my ($obj) = @_;
  
  my @categoryHashes = @{ $session->get('availableCategories') || [] };
  return \@categoryHashes if @categoryHashes;
  
  my $metaTreeMgr = $context->getSingleton( 'O2::Mgr::MetaTreeManager' );
  
  my @classNames = $context->getSingleton('O2::Mgr::ClassManager')->getSubClasses('O2CMS::Obj::Category');
  push @classNames, 'O2CMS::Obj::Category', 'O2CMS::Obj::Directory';
  my @categories = $context->getSingleton('O2::Mgr::ContainerManager')->objectSearch(
    metaClassName => { in => \@classNames },
  );
  
  foreach my $category (@categories) {
    my @path = $metaTreeMgr->getMetaObjectPathTo($category);
    shift @path; # remove installation object
    my $path = join '/', map { $_->getMetaName() } (@path, $category);
    push @categoryHashes, { value => $category->getId(), name => $path };
  }
  @categoryHashes = sort { $a->{name} cmp $b->{name} } @categoryHashes;
  $session->set('availableCategories', \@categoryHashes);
  $session->save();
  return \@categoryHashes;
}
#-----------------------------------------------------------------------------
sub _getQueryObject {
  my ($obj, %params) = @_;
  my %q = $obj->getParams();
  
  my $query;
  $query = $context->getObjectById( $q{id} ) if $q{id};
  
  my @classNames_likeAny = $obj->_translateWildcards( $q{className_likeAny} );
  my @names_likeAny      = $obj->_translateWildcards( $q{name_likeAny}      );
  
  my %searchParams;
  $searchParams{ metaName       }->{ likeAny } = \@names_likeAny          if @names_likeAny;
  $searchParams{ metaClassName  }->{ likeAny } = \@classNames_likeAny     if @classNames_likeAny;
  $searchParams{ metaClassName  }->{ in      } = $q{className_in}         if $q{className_in}         && @{ $q{className_in}         };
  $searchParams{ metaClassName  }->{ notIn   } = $q{className_notIn}      if $q{className_notIn}      && @{ $q{className_notIn}      };
  $searchParams{ metaStatus     }->{ in      } = $q{status_in}            if $q{status_in}            && @{ $q{status_in}            };
  $searchParams{ metaParentId   }->{ in      } = $q{parentId_in}          if $q{parentId_in}          && @{ $q{parentId_in}          };
  $searchParams{ ancestorId     }->{ in      } = $q{parentIdRecursive_in} if $q{parentIdRecursive_in} && @{ $q{parentIdRecursive_in} };
  $searchParams{ objectId       }->{ in      } = $q{objectId_in}          if $q{objectId_in}          && @{ $q{objectId_in}          };
  $searchParams{ metaOwnerId    }->{ in      } = $q{ownerId_in}           if $q{ownerId_in}           && @{ $q{ownerId_in}           };
  $searchParams{ metaOwnerId    }->{ notIn   } = $q{ownerId_notIn}        if $q{ownerId_notIn}        && @{ $q{ownerId_notIn}        };
  $searchParams{ metaChangeTime }->{ le      } = $q{changeTime_le}        if $q{changeTime_le};
  $searchParams{ metaChangeTime }->{ ge      } = $q{changeTime_ge}        if $q{changeTime_ge};
  $searchParams{ metaCreateTime }->{ le      } = $q{createTime_le}        if $q{createTime_le};
  $searchParams{ metaCreateTime }->{ ge      } = $q{createTime_ge}        if $q{createTime_ge};
  
  $searchParams{-limit}   = $q{limit}   if $q{limit};
  $searchParams{-orderBy} = $q{orderBy} if $q{orderBy};
  
  return $query unless %searchParams;
  
  $searchParams{metaParentId} = { gt    => 0                                     } unless $q{parentId_in};
  $searchParams{metaStatus}   = { notIn => [qw(trashed trashedAncestor deleted)] } unless $q{status_in}; # XXX Is this necessary?
  
  my $queryMgr = $context->getSingleton('O2::Mgr::Object::QueryManager');
  $query   = $queryMgr->updateObjectBySearchParams($query, %searchParams) if $query;
  $query ||= $queryMgr->newObjectBySearchParams(
    $context->getSingleton('O2::Mgr::ObjectManager'),
    %searchParams,
  );
  
  return $query;
}
#-----------------------------------------------------------------------------
# Translate * to %
sub _translateWildcards {
  my ($obj, $values) = @_;
  my @values;
  foreach my $value (@{$values}) {
    $value =~ s{ [*] }{%}xmsg;
    push @values, $value;
  }
  return @values;
}
#-----------------------------------------------------------------------------
sub _getQueryObjectAndResults {
  my ($obj) = @_;
  my $query = $obj->_getQueryObject();
  my @results = !$query || $query->isEmpty()  ?  ()  :  $query->getObjects();
  return ($query, @results);
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj) = @_;
  my ($query) = $obj->_getQueryObject();
  return $obj->error( $obj->getLang()->getString('o2.System.Search.errorNoCriteria') ) unless $query;
  
  my %q = $obj->getParams();
  $query->setMetaParentId( $q{folderId} ) if $q{folderId};
  $query->setMetaName(     $q{filename} ) if $q{filename};
  $query->setTitle(        $q{filename} ) if $q{filename};
  $query->save();
  
  return $obj->error('Could not save query object') unless $query->getId() > 0;
  return {
    id       => $query->getId(),
    filename => $query->getMetaName(),
  };
}
#-----------------------------------------------------------------------------
1;
