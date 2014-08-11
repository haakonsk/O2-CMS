var o2Navigation = {
  elements : new Array(),
  tags     : new Array("input", "textarea", "a", "select"), // Tags that support tabIndex

  /* Returns the next element of the same type as elm. Must be below root. */
  nextTag : function(elm, numTimes, root, dontWrap) {
    var tagName = elm.nodeName.toLowerCase();
    return o2Navigation.next(elm, numTimes, root, dontWrap, tagName);
  },

  previousTag : function(elm, numTimes, root, dontWrap) {
    var tagName = elm.nodeName.toLowerCase();
    return o2Navigation.previous(elm, numTimes, root, dontWrap, tagName);
  },

  /* Returns the next input element or link, obeying tabbing order (tabIndex)
     numTimes is an optional argument: repeats the function this number of times. */
  next : function(elm, numTimes, root, dontWrap, tagName) {
    numTimes = numTimes || 1;
    root     = root     || document;
    var nextElm;
    var elementsInOrder = o2Navigation._getElementsInOrder(root, tagName);
    for (var i = 0; i < elementsInOrder.length; i++) {
      if (elm === elementsInOrder[i]) {
        var nextIndex  =  numTimes > 0  ?  (i+1) % elementsInOrder.length  :  (elementsInOrder.length+i-1) % elementsInOrder.length;
        var wrapped  =  (numTimes > 0 && nextIndex < i)  ||  (numTimes < 0 && nextIndex > i);
        if (dontWrap && wrapped) { // Stop at the end / beginning
          return elm;
        }
        nextElm = elementsInOrder[nextIndex];
        if (!nextElm.id) {
          nextElm.id = parseInt( 1000000*Math.random() );
        }
        break;
      }
    }
    if (numTimes > 1) {
      nextElm = o2Navigation.next(nextElm, numTimes-1, root, dontWrap, tagName);
    }
    else if (numTimes < -1) {
      nextElm = o2Navigation.next(nextElm, numTimes+1, root, dontWrap, tagName);
    }
    return nextElm;
  },

  /* Returns the previous element, see comment for next */
  previous : function(elm, numTimes, root, dontWrap, tagName) {
    numTimes = numTimes || 1;
    return o2Navigation.next(elm, -numTimes, root, dontWraptagName);
  },

  invalidateCache : function() {
    o2Navigation.elements = new Array();
  },

  /* Returns an array with all tab-able elements in the page, in tabbing order. */
  _getElementsInOrder : function(root, tagName) {
    if (o2Navigation.elements.length > 0) {
      return o2Navigation.elements; // Returning cached result
    }
    var elements = new Array();
    var minTabIndex = 0;
    var maxTabIndex = 0;
    var tags = tagName ? new Array(tagName) : o2Navigation.tags;
    for (var i = 0; i < tags.length; i++) {
      var elms = root.getElementsByTagName( tags[i] );
      for (var j = 0; j < elms.length; j++) {
        var elm = elms[j];
        if (elm.disabled) {
          continue;
        }
        var tabIndex = parseInt(elm.tabIndex) == elm.tabIndex ? tabIndex : 0;
        maxTabIndex  = tabIndex > maxTabIndex ? tabIndex : maxTabIndex;
        minTabIndex  = tabIndex < minTabIndex ? tabIndex : minTabIndex;
        if (!elements[tabIndex]) {
          elements[tabIndex] = new Array();
        }
        elements[tabIndex].push(elm);
      }
    }
    for (var i = minTabIndex; i <= maxTabIndex; i++) {
      var elms = elements[tabIndex];
      for (var j = 0; elms && j < elms.length; j++) {
        o2Navigation.elements.push( elms[j] );
      }
    }
    return o2Navigation.elements;
  },

  /* Selects the specified element after 10 ms */
  select : function(elm) {
    if (!elm.id) {
      elm.id = parseInt( 1000000*Math.random() );
    }
    /* For some reason (bug in Firefox?), I can't call elm.focus() right away.. (Doesn't work when going from checkbox to text-input.) */
    setTimeout("o2Navigation._select('" + elm.id + "')", 10);
  },

  _select : function(id) {
    var elm = document.getElementById(id);
    elm.focus();
    elm.select();
  },

  /* Sets focus to the specified element after 10 ms */
  focus : function(elm) {
    if (!elm.id) {
      elm.id = parseInt( 1000000*Math.random() );
    }
    setTimeout("o2Navigation._focus('" + elm.id + "')", 10);
  },

  _focus : function(id) {
    var elm = document.getElementById(id);
    elm.focus();
  }

}
