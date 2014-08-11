function _closeApplicationFrame() {
  top.closeFrame(this.window.frameElement.name);
}

function _confirmCloseApplicationFrame() {
  top.confirmBox( top.o2.lang.getString("o2.desktop.confirmCloseApplication"), top.resolveFramePath(this.window) + "._callBackOnAskClose" );
}

function _confirmCloseApplicationFrameIfChanged() {
  if (FORM_CHANGED_SINCE_LOADED) {
    top.confirmBox( top.o2.lang.getString("o2.desktop.confirmCloseApplicationIfChanged"), top.resolveFramePath(this.window) + "._callBackOnAskClose" );
  }
  else {
    _closeApplicationFrame();
  }
}

function _callBackOnAskClose(bool) {
  if(bool) {
    _closeApplicationFrame();
  }
}

function settingsMenuCallMethod(method) {
  try {
    eval(method);
  }
  catch (e) {
    alert( top.o2.lang.getString("o2.desktop.errorCallingMethodInSettingsMenu", { "method" : method } ) );
  }
}


var FORM_CHANGED_SINCE_LOADED = false;

function setFormChanged(value) {
  if (value == null) {
    value = true;
  }
  if (value && window.console) {
    console.log("Form changed");
  }
  FORM_CHANGED_SINCE_LOADED = value;
}

function formIsChanged() {
  return FORM_CHANGED_SINCE_LOADED;
}
