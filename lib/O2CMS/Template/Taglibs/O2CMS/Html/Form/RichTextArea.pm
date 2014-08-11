package O2CMS::Template::Taglibs::O2CMS::Html::Form::RichTextArea;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{locale} = $params{parser}->{locale};
  $obj->{editors} = '';
  $obj->{parser}->registerTaglib('Html::Form');
  
  my %methods = (
    richtextarea => 'postfix',
  );
  
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
# Valid plugins: http://xinha.python-hosting.com/wiki/Plugins        
sub richtextarea {
  my ($obj, %params) = @_;
  my $counter = $obj->{parser}->getProperty('richTextAreaCounter') || 0;
  $obj->{parser}->setProperty( 'richTextAreaCounter',  ++$counter );
  
  my %localeValues;
  %localeValues = $obj->_getLocaleValues(%params) if $params{multilingual};
  $obj->_setupParams(\%params);
  $params{lang}  ||= 'en';
  $params{name}  ||= $params{id};
  $params{id}    ||= $obj->{parser}->getProperty('currentFormName') . "_$params{name}";
  $params{_type} ||= 'RichTextArea';
  
  $obj->addJs(
    content => qq{
      _editor_url  = "/js/xinha/";
      _editor_lang = "$params{lang}";
      _editor_skin = "silva";
    },
    where => "pre",
  );
  my $isAjaxRequest = $context->isAjaxRequest();
  $obj->addJs( content => "xinha_init();",                         where => "onLoad" ) if $obj->{parser}->getProperty('richTextAreaCounter') == 1 && !$isAjaxRequest;
  $obj->addJs( content => "richText_initDragDrop('$params{id}');", where => "onLoad" ) if $context->isBackend();
  
  $obj->addJsFile( file => 'xinha/XinhaCore',           where => 'post' );
  $obj->addJsFile( file => 'xinhaO2/o2_default_config', where => 'post' );
  
  $obj->addJsFile( file => 'xinhaO2/xinhaDragDrop'        ) if $context->isBackend();
  $obj->addJsFile( file => 'xinhaO2/xinhaCheckOnKeyPress' );
  $obj->addJsFile( file => 'dragDrop'                     ) if $context->isBackend();
  
  my $jsLangTaglib = $obj->{parser}->getTaglibByName('Js::Lang');
  $jsLangTaglib->addJsLangFile( file => 'o2.richTextArea' );
  
  my $plugins = "'CheckOnKeyPress',";
  my @confPlugins = @{ $config->get('xinha.plugins') };
  foreach my $plugin (@confPlugins) {
    next if lc $plugin eq 'stylist' && !-e $context->getEnv('O2CUSTOMERROOT') . '/var/www/css/editor.css'; # if the stylist CSS file doesn't exists, don't load the plugin
    $plugins .= "'$plugin',";
  }
  # XXX Should we respect $params{loadPlugin} ??
  
  $plugins = substr $plugins, 0, -1;
  
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  
  $params{content} = '' if $params{value};
  my $inputFieldHtml = $obj->_createLocaleFields(\%params, \%localeValues, 'textarea', 0);
  
  my $postJs = qq{
    var xinha_plugins = [ $plugins ];
    window.xinha_editor_names = window.xinha_editor_names || []
    xinha_editor_names.push( '$params{id}' );
  };
  $postJs .= qq{
    var new_xinha_editors = HTMLArea.makeEditors(['$params{id}'], xinha_config, xinha_plugins);
    HTMLArea.startEditors(new_xinha_editors);
    xinha_editors['$params{id}'] = new_xinha_editors['$params{id}'];
  } if $isAjaxRequest;
  $obj->addJs(
    content => $postJs,
    where   => 'post',
  );
  
  return $pre . $inputFieldHtml . $post;
}
#--------------------------------------------------------------------------------------------
1;
