o2.hideFrameScrollbars = function(e, frame) {
  if (e.evt.relatedTarget) {
    return;
  }
  if (frame && frame.frameElement) {
    frame = frame.frameElement;
  }
  if (frame && frame.contentDocument) {
    frame.contentDocument.body.parentNode.style.overflow = "hidden";
  }
}

o2.showFrameScrollbars = function(e, frame) {
  if (e.evt.relatedTarget) {
    return;
  }
  if (frame && frame.frameElement) {
    frame = frame.frameElement;
  }
  if (frame && frame.contentDocument) {
    frame.contentDocument.body.parentNode.style.overflow = "";
  }
}

o2.addFrameScrollbarEvents = function(win, frame) {
  o2.addEvent( frame.window, "mouseover", function(e) { o2.hideFrameScrollbars(e, win); } );
  o2.addEvent( frame.window, "mouseout",  function(e) { o2.showFrameScrollbars(e, win); } );
}
