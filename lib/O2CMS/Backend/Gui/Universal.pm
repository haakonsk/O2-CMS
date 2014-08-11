package O2CMS::Backend::Gui::Universal;

use strict;

use base 'O2CMS::Backend::Gui';

use O2 qw($context $cgi $config);
use Data::Dumper;

#-----------------------------------------------------------------------------------------
sub newObject {
  my ($obj) = @_;
  $obj->editObject('newObject');
}
#-----------------------------------------------------------------------------------------
sub _generateTemplateOnTheFly {
  my ($obj, $className) = @_;
  require O2::Model::Generator;
  my $generator = O2::Model::Generator->new();

  my $html = $generator->generate(
    'view',
    className => $className,
    messages  => 0,
    questions => 0,
    wantsHtml => 1,
  );
  my %q = $obj->getParams();
  require O2::Template;
  my $template = O2::Template->newFromString(\$html);
  my $htmlRef = $template->parse(
    lang   => $obj->{lang},
    q      => \%q,
    object => $context->getObjectById( $q{objectId} ),
    config => $config,
  );
  $html = ${$htmlRef};
  print $html;
}
#-----------------------------------------------------------------------------------------
sub editObject {
  my ($obj, $mode) = @_;
  $mode ||= 'edit';

  my $universalMgr = $context->getSingleton( 'O2::Mgr::UniversalManager' );
  my $treeMgr      = $context->getSingleton( 'O2::Mgr::MetaTreeManager'  );
  my $classMgr     = $context->getSingleton( 'O2::Mgr::ClassManager'     );

  my ($object, @path, $templatePath);
  if ($mode eq 'edit') {
    $object = $context->getObjectById( $cgi->getParam('objectId') );
    $obj->error("Object not found") unless $object;
    eval {
      $templatePath = $classMgr->getEditTemplateByObjectId( $cgi->getParam('objectId') );
    };
    if ($@) {
      # Didn't find template path, so we try to generate the template on the fly.
      my $className = ref $object;
      $obj->_generateTemplateOnTheFly($className);
      return;
    }
    @path = $treeMgr->getMetaObjectPathTo($object);
  }
  else {
    my $class = webClassName2PerlClassName($cgi->getParam('class'));
    $obj->display('errorSavingObject.html', error => 'No classname set') unless $class;
    $object = $universalMgr->newObjectByClassName($class);
    $object->setMetaParentId($obj->getParam('parentId')) if !$object->getMetaParentId();
    if ($object->getMetaParentId()) {
      @path = $treeMgr->getMetaObjectPath( $object->getMetaParentId() ); # Traverses parents and appends itself
    }
    $templatePath = $classMgr->getEditTemplateByClassName($class);
  }
  
  $object->registerClass() if !$templatePath && $object->can('registerClass');
  
  if ($templatePath !~ m{ \A / }xms) {
    $templatePath = $context->getSingleton('O2::File')->resolvePath("o2://var/templates/$templatePath");
  }
  $obj->display(
    'editFramework.html',
    includeTemplatePath => $templatePath,
    object              => $object,
    mode                => $mode,
    path                => \@path,
  );
}
#-----------------------------------------------------------------------------------------
sub saveObject {
  my ($obj) = @_;

  my %q = $cgi->getParams();

  my $object;

  my $universalMgr = $context->getSingleton('O2::Mgr::UniversalManager');

  if ( $cgi->getParam('mode') eq 'newObject') {
    my $class = webClassName2PerlClassName( $cgi->getParam('object.metaClassName') );
    $obj->display('errorSavingObject.html', error => 'No classname set') unless $class;
    $object = $universalMgr->newObjectByClassName($class);
  }
  else {
    $object = $context->getObjectById( $cgi->getParam('objectId') );
    $obj->error("Object not found") unless $object;
  }

  my $objectStructure = $cgi->getStructure('object');

  # If $objectStructure contains javascript-stuff, we need to "expand" the js-structure.

  my $filteredOk = $obj->filter($object, $objectStructure);
  return $obj->display('errorSavingObject.html', error => $@) unless $filteredOk;

  eval {
    my $model = $object->getModel();
    require O2::Util::AccessorMapper;
    my $accessorMapper = O2::Util::AccessorMapper->new();

    if ($objectStructure) {
      my %multilingualFields;
      foreach my $field (keys %{$objectStructure}) {
        next if $field !~ m{ \A \w+ \z }xms;
        if ($field =~ m{ \A  \w\w_\w\w  \z }xms  &&  ref $objectStructure->{$field} eq 'HASH') {
          my $locale = $field;
          $object->setCurrentLocale($locale);
          print "$locale ";
          foreach my $_field (keys %{ $objectStructure->{$locale} }) {
            $multilingualFields{$_field} = 1;
            print "isMultilingual [$_field = $objectStructure->{$locale}->{$_field}] ";
            $accessorMapper->setAccessors($object, $_field, $objectStructure->{$locale}->{$_field});
          }
        }
        else {
          if (!$multilingualFields{$field}) {
            my $struct = $objectStructure->{$field};
            if ($model->getFieldByName($field)->getListType() eq 'hash') {
              $struct = {};
              my @keys = @{ $objectStructure->{$field}->{key} };
              for my $i (0 .. @keys-1) {
                my $key   = $keys[$i];
                my $value = $objectStructure->{$field}->{value}->[$i];
                $struct->{$key} = $value;
              }
            }
            $struct = $struct->dbFormat() if ref $struct eq 'O2::Cgi::DateTime';
            my $fieldValue = ref $objectStructure->{$field}  ?  Dumper($struct)  :  $struct;
            $fieldValue    =~ s{\$O2STRIP1 = }{}ms;
            $fieldValue    =~ s{ ; \s* \z }{}xms;
            print "isMonolingual [$field = $fieldValue] ";
            $accessorMapper->setAccessors($object, $field, $struct);
          }
          else {
            print "Skipping [$field] (isMultilingual) ";
          }
        }
        print "<br>\n";
      }
    }

    $object->save();

    return $obj->display(
      'savedObject.html',
      object => $object,
      mode   => $cgi->getParam('mode'),
    );
  };
  my $errorMsg = $@;
  if ($errorMsg) {
    $errorMsg =~ s{ \n }{\\n}xmsg; # An actual new line in a javascript string gives us an error. Backslash-n (\n) is ok.
    $obj->display('errorSavingObject.html', error => $errorMsg);
  }
}
#-----------------------------------------------------------------------------------------
sub filter {
  return 1;
}
#-----------------------------------------------------------------------------------------
sub webClassName2PerlClassName {
  my ($webClassName) = @_;
  $webClassName =~ s/-/::/g;
  return $webClassName;
}
#-----------------------------------------------------------------------------------------
sub callObjectMethod {
  my ($obj) = @_;
  eval {
    my $methodName = $obj->getParam('methodName');
    my $object = $context->getObjectById( $obj->getParam('objectId') );
    return {
      returnValue => scalar $object->$methodName(),
    };
  };
  $obj->error($@) if $@;
}
#-----------------------------------------------------------------------------------------
1;
