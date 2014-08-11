var o2_currentController = null;
var o2_currentElement    = null;
//-------------------------------------------------------------------------------------------------
function o2_markElement(event) {
  var element = o2_getNearestEditableElement(event.target);
  
  if (element) {
    
    if (typeof(jQuery) == 'undefined') {
      // jQuery is missing
      o2.require('/js/jquery.js');
    }
    else {
      // mark element with class o2_activeElement
      $(element).addClass('o2_activeElement');
      
      // Add event listener on element for mouse out
      element.addEventListener('mouseout', o2_unMarkElement, false);
      
      // Create and place controller at element
      o2_createAndShowController(element);
      
      o2_currentElement = element;
      element.addEventListener('click', o2_activateElement, false);
    }
  }
}
//-------------------------------------------------------------------------------------------------
function o2_unMarkElement(event) {
  // Remove class for active element and turn off inline editing
  var element = o2_getNearestEditableElement(event.target);
  
  if (element) {
    $(element).removeClass('o2_activeElement');
    element.setAttribute('contentEditable', 'false');
  }
}
//-------------------------------------------------------------------------------------------------
function o2_createAndShowController(element) {
  if (element) {
    
    // Remove the previous controller
    if (o2_currentController) {
      o2_currentController.parentNode.removeChild(o2_currentController);
      o2_currentController = null;
    }
    
    // Add frontend.css
    o2.require('/css/frontendEdit.css');
    
    // Create edit control
    var controller = document.createElement('DIV');
    controller.setAttribute('class', 'o2_controller');
    controller.innerHTML   = '<a href="javascript:o2_editContent()">Edit</a> | <a href="javascript:o2_saveContent()">Save</a>';
    controller.style.top   = (element.offsetTop - 10) + 'px';
    controller.style.left  = element.offsetLeft + 'px';
    
    
    document.body.appendChild(controller);
    o2_currentController = controller;
  }
}
//-------------------------------------------------------------------------------------------------
function o2_removeElement() {
  if (o2_currentElement) {
    
    // Remove the previous controller
    if (o2_currentController) {
      o2_currentController.parentNode.removeChild(o2_currentController);
      o2_currentController = null;
    }
    
    o2_currentElement.parentNode.removeChild(o2_currentElement);
  }
}
//-------------------------------------------------------------------------------------------------
function o2_editContent() {
  if (o2_currentElement) {
    console.debug('EDIT: objectId: ' + o2_currentElement.getAttribute('o2_objectId') + ' fieldName: ' + o2_currentElement.getAttribute('o2_fieldName') + ' HTML: ' + o2_currentElement.innerHTML);
  }
}
//-------------------------------------------------------------------------------------------------
function o2_saveContent(element) {
  if (o2_currentElement) {
    console.debug('SAVE: objectId: ' + o2_currentElement.getAttribute('o2_objectId') + ' fieldName: ' + o2_currentElement.getAttribute('o2_fieldName') + ' HTML: ' + o2_currentElement.innerHTML);
  }
}
//-------------------------------------------------------------------------------------------------
function o2_activateElement(event) {
  // Check if the clicked element is tagged up with an objectId
  var element = o2_getNearestEditableElement(event.target);
  if (element) {
    // Enable edit mode on target element
    element.setAttribute('contentEditable', 'true');
  }
  if (element && element.getAttribute('contentEditable')) {
    // Stop normal event handler on element
    event.returnValue = false;
  }
  
}
//-------------------------------------------------------------------------------------------------
function o2_getNearestEditableElement(element) {
  if (typeof(element) == 'object') {
    if (element.getAttribute('o2_objectId') && element.getAttribute('o2_fieldName') ) {
      // The parentNode already have our parameters, it is editable, we can use it.
      return element;
    }
    else if (element.parentNode && element.parentNode.tagName !== 'BODY') {
      // We stop at BODY, no need to continue searching for editable elements
      return o2_getNearestEditableElement(element.parentNode);
    }
  }
  else {
    // No suitable elements found
    return null;
  }
}
//-------------------------------------------------------------------------------------------------
// Make sure document is ready
// http://www.javascriptkit.com/dhtmltutors/domready.shtml
var alreadyrunflag = 0; //flag to indicate whether target function has already been run

if (document.addEventListener) {
  document.addEventListener(
    "DOMContentLoaded",
    function() {
      alreadyrunflag = 1;
      document.body.addEventListener('mouseover', o2_markElement, false);
    },
    false
  );
}
else if (document.all && !window.opera) {
  document.write('<script type="text/javascript" id="contentloadtag" defer="defer" src="javascript:void(0)"><\/script>');
  var contentloadtag = document.getElementById("contentloadtag");
  contentloadtag.onreadystatechange = function() {
    if (this.readyState == "complete") {
      alreadyrunflag = 1;
      document.body.addEventListener('mouseover', o2_markElement, false);
    }
  }
}

window.onload = function() {
  setTimeout("if (!alreadyrunflag){document.body.addEventListener('mouseover', o2_markElement, false);}", 0);
}
