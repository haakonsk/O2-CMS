package O2CMS::Mgr::ArticleManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2 qw($context $config);
use O2CMS::Obj::Article;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2CMS::Obj::Article',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    title           => { type => 'varchar', multilingual => 1                  },
    texts           => { type => 'text', listType => 'hash', multilingual => 1 },
    isSearchable    => { type => 'bit', defaultValue => '0'                    },
    publishTime     => { type => 'int'                                         },
    unPublishTime   => { type => 'int'                                         },
    publishableUrls => { type => 'varchar', listType => 'array'                },
    relatedArticles => { type => 'O2CMS::Obj::Article', listType => 'array'    },
    images          => { type => 'O2::Obj::Image', listType => 'array'         }, # The images used by this article. Makes it easier to see which articles use a given image than if we have to search the html.
    #-----------------------------------------------------------------------------
  );
}
#--------------------------------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  
  my $isUpdate = $object->getId() > 0;
  $obj->SUPER::save($object);
  
  # XXX Implement this as an event that runs with "runLater"
  require O2CMS::Search::ObjectIndexer;
  
  # Default indexer (o2Generic)
  my $objectIndexer = O2CMS::Search::ObjectIndexer->new();
  
  # If a custom index is defined we will use that index in addition to the default one
  my $customIndexName = $config->get('o2.search.searchIndexes.article');
  my $customIndexer;
  $customIndexer = O2CMS::Search::ObjectIndexer->new( indexName => $customIndexName ) if $customIndexName;
  
  if ($object->isSearchable()) {
    $object->setPropertyValue('allowIndexing', 'yes');
    $objectIndexer->addOrUpdateObject($object);
    $customIndexer->addOrUpdateObject($object) if $customIndexer;
  }
  else {
    $object->setPropertyValue('allowIndexing', 'no');
    $objectIndexer->removeObject($object);
    $customIndexer->removeObject($object) if $customIndexer;
  }
  
  return $object->getId();
}
#--------------------------------------------------------------------------------------------------
sub saveDraft {
  my ($obj, $object, $draft) = @_;
  
  die "\$object is a draft object"                            if           ref ($object) eq 'O2CMS::Obj::Draft';
  die "\$draft is not a draft object (" . ref ($object) . ')' if $draft && ref ($draft)  ne 'O2CMS::Obj::Draft';
  
  my $draftMgr = $context->getSingleton('O2CMS::Mgr::DraftManager');
  if (!$draft && $object->getId() && ref ($object) eq 'O2CMS::Obj::Draft') {
    $draft = $context->getObjectById( $object->getId() );
  }
  if (!$draft && $object->getMetaParentId()) {
    $draft = $draftMgr->newObject();
    $draft->setMetaParentId( $object->getMetaParentId() );
  }
  die 'No draft' unless $draft;
  
  $draft->setMetaParentId(undef) if $object->getId() && $draft->getMetaParentId();
  if (!$draft->getMetaName()) {
    require O2::Util::Password;
    my $passwordGenerator = O2::Util::Password->new();
    $draft->setMetaName( 'draft-' . $passwordGenerator->generatePassword() );
  }
  $obj->saveRevision(
    $object,
    revisionedObject => $draft,
  );
  return $draft;
}
#--------------------------------------------------------------------------------------------------
1;
