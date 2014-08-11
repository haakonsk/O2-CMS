function DesktopDragReceiver(elmId) {}

DesktopDragReceiver.prototype.ondrop = function(source, target, event) {
  desktop.handleOnDropEvent(source,target,event);                                     
}

DesktopDragReceiver.prototype.getDragDataById = function(id) {}
    
