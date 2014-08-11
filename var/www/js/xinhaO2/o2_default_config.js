xinha_editors = null;
xinha_init    = null;
xinha_config  = null;
xinha_plugins = null;

// This contains the names of textareas we will make into Xinha editors
xinha_init = xinha_init ? xinha_init : function()
{
  /** STEP 1 ***************************************************************
   * First, what are the plugins you will be using in the editors on this
   * page.  List all the plugins you will need, even if not all the editors
   * will use all the plugins.
   ************************************************************************/

  HTMLArea.externalPlugins = { // This is a hack to load a plugin from outside of the xinha directory
    "CheckOnKeyPress" : [
      '',
      '/js/xinhaO2/xinhaCheckOnKeyPress.js'
    ]
  };
  // Don't need this. We define plugins in xinha.conf
  // xinha_plugins = xinha_plugins ? xinha_plugins :
  //   [
  //     'CheckOnKeyPress'
  //     'CharacterMap',
  //     'ContextMenu',
  //     'FullScreen',
  //     'ListType',
  //     'SpellChecker',
  //     'Stylist',
  //     'SuperClean',
  //     'TableOperations'
  //   ];

  // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  :)
  if (!HTMLArea.loadPlugins(xinha_plugins, xinha_init)) {
    return;
  }

  /** STEP 2 ***************************************************************
   * Now, what are the names of the textareas you will be turning into
   * editors?
   ************************************************************************/

  xinha_editor_names = xinha_editor_names ? xinha_editor_names : [];

  /** STEP 3 ***************************************************************
   * We create a default configuration to be used by all the editors.
   * If you wish to configure some of the editors differently this will be
   * done in step 5.
   *
   * If you want to modify the default config you might do something like this.
   *
   *   xinha_config = new HTMLArea.Config();
   *   xinha_config.width  = '640px';
   *   xinha_config.height = '420px';
   *
   *************************************************************************/
  if (xinha_config == null) {
    xinha_config = new HTMLArea.Config();
  }
  xinha_config.statusBar = false;
  // xinha_config.autofocus = true;
  // xinha_config.SpellChecker.utf8_to_entities = false;
  // xinha_editors.editor.config.SpellChecker.utf8_to_entities = false;


  xinha_config.registerButton({
    id       : "insertO2Content",      // the ID of your button
    tooltip  : "Insert O2 content",    // the tooltip
    image    : "/images/system/content.gif",  // image to be displayed in the toolbar
    textMode : false,            // disabled in text mode
    action   : function(editor) { // called when the button is clicked
      window._currentXinhaEditor = editor;
      var parentId = '';
      if (window.getParentId) {
        parentId = window.getParentId();
      }
      window.open('/o2cms/Article-ObjectManager/insertObjectPopup?parentId='+parentId+'', 'insertObjectPopup', 'status=0,location=0,toolbar=0,menubar=0,directories=0,resizable=1,scrollbars=0,width=760,height=580');
    },
    context : "" // will be disabled if outside a <p> element
  });

  xinha_config.addToolbarElement(['insertO2Content'], ["insertimage"], +1);

      
  // XXX get this from a cookie or something?

  if (xinha_config.SpellChecker) {
    xinha_config.SpellChecker.defaultDictionary = 'no';
    // xinha_config.SpellChecker.backend           = 'perl'; // php-backend doesn't handle Norwegian characters
    xinha_config.SpellChecker.personalFilesDir  = top.getCustomerRoot() + "/var/xinha";
    xinha_config.SpellChecker.utf8_to_entities  = false;
  }

  /** Nilschd, setting up the default CSS file for this customer */
  /** currently "editor.css" is the css to be used */
  if (typeof Stylist != 'undefined') {
    xinha_config.stylistLoadStylesheet('/css/editor.css');
    //document.location.href.replace(/[^\/]*\.html/, 'stylist.css'));
  }
 
/*
  if (typeof ListType != 'undefined') {
    xinha_config.ListType.mode = "panel";
  }
*/

  /** STEP 4 ***************************************************************
   * We first create editors for the textareas.
   *
   * You can do this in two ways, either
   *
   *   xinha_editors   = HTMLArea.makeEditors(xinha_editor_names, xinha_config, xinha_plugins);
   *
   * if you want all the editor objects to use the same set of plugins, OR;
   *
   *   xinha_editors = HTMLArea.makeEditors(xinha_editor_names, xinha_config);
   *   xinha_editors['myTextArea'].registerPlugins(['Stylist','FullScreen']);
   *   xinha_editors['anotherOne'].registerPlugins(['CSS','SuperClean']);
   *
   * if you want to use a different set of plugins for one or more of the
   * editors.
   ************************************************************************/

  xinha_editors = HTMLArea.makeEditors(xinha_editor_names, xinha_config, xinha_plugins);

  /** STEP 5 ***************************************************************
   * If you want to change the configuration variables of any of the
   * editors,  this is the place to do that, for example you might want to
   * change the width and height of one of the editors, like this...
   *
   *   xinha_editors.myTextArea.config.width  = '640px';
   *   xinha_editors.myTextArea.config.height = '480px';
   *
   ************************************************************************/


  /** STEP 6 ***************************************************************
   * Finally we "start" the editors, this turns the textareas into
   * Xinha editors.
   ************************************************************************/

  HTMLArea.startEditors(xinha_editors);
}


// Make sure activateEditor isn't called on an editor without our knowledge (during initialization)
top.ALLOWED_EDITOR = null;
var OLD_ACTIVATE_FUNC = Xinha.prototype.activateEditor;
var ACTIVATE_EDITOR_LOCKED = false;

Xinha.prototype.activateEditor = function() {
  if ((top.ALLOWED_EDITOR  &&  this._textArea.id !== top.ALLOWED_EDITOR)  ||  ACTIVATE_EDITOR_LOCKED) {
    return;
  }
  ACTIVATE_EDITOR_LOCKED = true;
  try {
    OLD_ACTIVATE_FUNC.apply(this, arguments);
  }
  catch (e) {
    ACTIVATE_EDITOR_LOCKED = false; // Got to unlock when an error occurs, too
    throw e;
  }
  ACTIVATE_EDITOR_LOCKED = false;
}
