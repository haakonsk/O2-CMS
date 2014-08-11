package O2Plugin::Shop::Mgr::Product::VariantManager;

use strict;

use base 'O2::Mgr::ObjectManager';

use O2Plugin::Shop::Obj::Product::Variant;

#-----------------------------------------------------------------------------
sub initModel {
  my ($obj, $model) = @_;
  $obj->SUPER::initModel($model);
  $model->registerFields(
    'O2Plugin::Shop::Obj::Product::Variant',
    # Your class definition goes here:
    #-----------------------------------------------------------------------------
    name         => { type => 'varchar', multilingual => 1                                         },
    unit         => { type => 'varchar', multilingual => 1                                         },
    description  => { type => 'text',    multilingual => 1                                         },
    defaultValue => { type => 'varchar', multilingual => 1                                         },
    valueType    => { type => 'varchar'                                                            },
    minLength    => { type => 'int'                                                                },
    maxLength    => { type => 'int'                                                                },
    minValue     => { type => 'float'                                                              },
    maxValue     => { type => 'float'                                                              },
    validValues  => { type => 'varchar', listType => 'array'                                       },
    optionIds    => { type => 'O2Plugin::Shop::Obj::Product::Variant::Option', listType => 'array' },
    #-----------------------------------------------------------------------------
  );
}
#-----------------------------------------------------------------------------
sub save {
  my ($obj, $object) = @_;
  $object->setMetaName( $object->getName() ) unless $object->getMetaName();
  $obj->SUPER::save($object);
}
#-----------------------------------------------------------------------------
1;
