o2.require("/js/DOMUtil.js");

var ___tabLayerCount=0;
var ___defaultClassNamePrefix="tabLayer";
var ___tabLayers = null;
var ___defaultOverlap = -15; //this how mush the tabs should overlap

function TabLayer(id,className,properties) {
    ___tabLayerCount++;
    if(properties == null) {
        properties = new Array();
    }
    if(id == null) {
        this.id = "TabLayer_"+___tabLayerCount;
    }
    else {
        this.id = id;
    }
    
    if(className == null) {
        this.className = ___defaultClassNamePrefix;
    }
    else {
        this.className = className;
    }
    
    var thisElm = document.getElementById(this.id);
    if(thisElm == null) {
        alert("TabLayer:\n- could not get parent container element with id : "+this.id);
        return null;
    }
    thisElm.className = this.className;
    
    //building the tabRow;
    var tabRow = document.getElementById(this.id+"Row");
    if(tabRow == null) {
        tabRow = document.createElement("DIV");
        tabRow.id = this.id+"Row";
        tabRow.className= this.className+"Row";
        // tabRow.style.border="0px";
        document.getElementById(this.id).appendChild(tabRow);
    }
    
    var empty = document.createElement("DIV");
    empty.innerHTML="";
    empty.className=this.className+"SpaceRow";
   // document.getElementById(this.id).appendChild(empty);
    tabRow.appendChild(empty);
    
    if(properties["showCloseButton"]) {
        var a = document.createElement("A");
        a.id=this.id+"CloseButton";
        a.className=this.className+"CloseButton";
        a.href="#"; //javascript:void(___closeCurrentTab('"+this.id+"'));";
        a.onmousedown = new Function("javascript:void(___closeCurrentTab('"+this.id+"'));");
        empty.appendChild(a);
    }
    else if(properties["tabShowCloseButton"]) {
        this.tabShowCloseButton=true;
    }
    
    //buiding the body div
    var tabBody = document.getElementById(this.id+"Body");
    if(tabBody == null) {
        tabBody = document.createElement("DIV");
        tabBody.id = this.id+"Body";
        tabBody.className= this.className+"Body";
//        tabBody.style.border="0px solid red";
        tabBody.style.height = 0;
        //        tabBody.style.height='100%';
        document.getElementById(this.id).appendChild(tabBody);

    }
    this.tabOverlap = (properties['tabOverLap']!=null?parseInt(properties['tabOverLap']):___defaultOverlap);
    // alert(this.tabOverlap);
    this.tabs = new Array();
    this.selectedTabId = null;
    this.rememberSelectedTab = false;
    
    if(___tabLayers == null) ___tabLayers = new Array();
    ___tabLayers[this.id] = this;
    return this;
}


TabLayer.prototype.addTab = function(name, contentId, activeClassName, inActiveClassName) {
    
    var tabRow = document.getElementById(this.id+"Row");
    //var tabRow = document.getElementById(this.id+"tabContainer");
    var tab = document.createElement("SPAN");

    var div = document.createElement("DIV");
    div.innerHTML=name;
    // tab.appendChild(document.createTextNode(name));
    tab.appendChild(div);
    if(this.tabCount == null) this.tabCount=0;
    tab.id = this.id+"_tab"+this.tabCount++;
    div.id = tab.id+"_title";
    tab.className = (inActiveClassName != null?inActiveClassName:this.className+"TabItem");
    // tab.setAttribute("href","javascript:void(___selectTab('"+this.id+"','"+tab.id+"'));");
    tab.onmousedown = new Function("javascript:void(___selectTab('"+this.id+"','"+tab.id+"'));");
    
    var tabItem = new TabItem(this,tab.id,activeClassName, inActiveClassName);
    this.tabs[tab.id] = tabItem;

    if(this.tabShowCloseButton) {
        var a = document.createElement("A");
        a.id=tab.id+"_closeButton";
        a.className=this.className+"tabCloseButton";
        a.href="#"; //javascript:void(___closeCurrentTab('"+this.id+"'));";
        a.onmousedown = new Function("javascript:void("+this.id+".closeTab('"+tab.id+"'));");
        tab.appendChild(a);
    }
        
    // this.tabs[tab.id]['content'] = null;
    
    if(contentId != null) {
        this.setContentFromElement(tab.id,contentId);
    }
    
    if(this.tabCount-1 > 0) {
        tab.style.left = this.tabOverlap*(this.tabCount-1);
    }
    //fix to avoid tabs to swap to next line, when tabs total width execeds the row width
    //some how I can't rely on the overlap prop to fix this.
    
    var oldWidth = null;
    if(this.tabOverlap < 0) {
        oldWidth = tabRow.offsetWidth;
        tabRow.style.width=parseInt(oldWidth)+(this.tabOverlap*-1);
    }
    tabRow.appendChild(tab);
    
    if(oldWidth != null) {
        tabRow.style.width = oldWidth;
    }
    //this.realignTabs();
    return tabItem;
}

TabLayer.prototype.closeTab = function(tabId) {
    if(this.tabs[tabId].getCloseAble() == false) return;
    var tab = document.getElementById(tabId);
    if(tab == null) return;
    var tabRow = document.getElementById(this.id+"Row");
    tabRow.removeChild(tab);
    
    var tabContent = document.getElementById(tabId+"_temporay_hidden");
    document.getElementById(this.id+"Body").removeChild(tabContent);
    
    var tmp = new Array();
    var nextSelectedTab = null;
    for(elm in this.tabs) {
        if(elm != tabId) {
            tmp[elm] =this.tabs[elm];
            nextSelectedTab = elm;
        }
    }
    this.tabs = tmp;

    if(nextSelectedTab != null) {
        this.selectTab(nextSelectedTab);
    }
    this.realignTabs();
}

TabLayer.prototype.closeCurrentTab = function() {
        this.closeTab(this.selectedTabId);
}

TabLayer.prototype.setBodyHeight = function(height) {
        var tabBody = document.getElementById(this.id+"Body");

        if(tabBody.firstChild != null && typeof(tabBody.firstChild) == 'object') {
                try {
                    tabBody.firstChild.style.height=height+"px";
                } catch(e) {}
        }

}

TabLayer.prototype.setContent = function(tabId, contentRef) {
        if(this.tabs[tabId] == null) {
                alert("TabLayer setContent:\n- no such tab with tabId "+tabId);
                 return false;
        }
        this._setContent(tabId,contentRef);
}

TabLayer.prototype.getContent = function(tabId) {
        if(this.tabs[tabId] == null) {
                alert("TabLayer getContent:\n- no such tab with tabId "+tabId);
                 return false;
        }
        // return this.tabs[tabId]['content'];
        return this._getContent(tabId);

}


TabLayer.prototype.setContentFromElement = function(tabId, contentId) {
        var contentElm = document.getElementById(contentId);
        if(contentElm == null) {
                alert("TabLayer setContentFromElement:\n- could not add component with id "+contentId);
                return false;
        }
        
        if(this.tabs[tabId] == null) {
                alert("TabLayer setContentFromElement:\n- no such tab with tabId "+tabId);
                return false;
        }
        
        this._setContent(tabId,contentElm);
}
//temporary storage for elements
TabLayer.prototype._setContent = function(tabId,contentRef) {
        var tabContentHeight = parseInt( o2.getComputedStyle(contentRef, "height") );
        var div = document.getElementById(tabId+"_temporay_hidden");
        var tabLayerBody = document.getElementById( this.id + "Body" );
        if(div == null) {
                var div=document.createElement("DIV");
                div.id=tabId+"_temporay_hidden";
                div.style.display="none";
                div.style.top="0px";
                div.style.left="0px";
                //  div.style.border="0px";// solid red";
                div.style.height="100%";
                div.style.width="100%";
                tabLayerBody.appendChild(div);
                var tabLayerBodyHeight = parseInt( o2.getComputedStyle(tabLayerBody, "height") );
                if (tabContentHeight  >  tabLayerBodyHeight) {
                  tabLayerBody.style.height = tabContentHeight + "px";
                }
        }
        else {
                while( div.hasChildNodes() )  {
                        try {
                                div.removeChild( div.firstChild );
                        } catch(e) { }
                }
        }
        contentRef.style.display="";
        contentRef.style.visibility="visible";
        div.appendChild(contentRef);


}

TabLayer.prototype._getContent = function(tabId) {
        var div = document.getElementById(tabId+"_temporay_hidden");
        if(div == null) {
                return null;
        }
        return div.firstChild;
}

TabLayer.prototype._showContent = function(tabId) {
    var body = document.getElementById(this.id+"Body");
    
    
    if(this.selectedTabId != null) {
        var elm = document.getElementById(this.selectedTabId+"_temporay_hidden");
        // alert(elm);
        if(elm !=null)
          elm.style.display="none";
    }
    var hiddenContent = document.getElementById(tabId+"_temporay_hidden");
    if(hiddenContent != null) {
      hiddenContent.style.display="";
    }
    //var contentRef = this._getContent(tabId);
    // if(contentRef != null && contentRef != '') {
    // body.appendChild(contentRef);
    // contentRef.style.visibility="visible";
    // contentRef.style.display="";
    //}
}

TabLayer.prototype.selectTab= function(tabId) {
        if(this.tabs[tabId] == null) {
            //alert("TabLayer selectTab:\n- no such tab with tabId: "+tabId);
                return false;
        }
        
        if(this.rememberSelectedTab) {
                this._setCookie(this.id+"_selectedTab",tabId);
        }
        this.tabs[tabId].execPreActions();

        this._showContent(tabId);

        // this.tabs[tabId].style.visibility="visible";

        var zIndex=this.tabCount;
        for(elm in this.tabs) {
                //does this tab have on CSS defs?                          
                var tabActiveCSSClassName = (this.tabs[elm].activeTabCSSClassName != null?this.tabs[elm].activeTabCSSClassName:this.className+"TabItemActive");
                var tabInActiveCSSClassName = (this.tabs[elm].inActiveTabCSSClassName != null?this.tabs[elm].inActiveTabCSSClassName:this.className+"TabItem");

                var tabElm = document.getElementById(elm);
                //  var left = tabElm.style.left;
                if(tabElm != null) {
                if(elm == tabId) {
                        tabElm.className = tabActiveCSSClassName;
                        tabElm.style.zIndex= this.tabCount;
                }
                else {
                        //alert(tabElm.id+" "+tabInActiveCSSClassName);
                        if(tabElm.className == tabActiveCSSClassName) 
                                tabElm.className = tabInActiveCSSClassName;
                        tabElm.style.zIndex=zIndex;
                        //tabElm.setAttribute("z-index",zIndex);
                }
                zIndex--;
                }
        }
        
        this.tabs[tabId].execPostActions();
        this.selectedTabId=tabId;
                this.realignTabs();
}

TabLayer.prototype.getActiveTab= function() {
        return this.tabs[this.selectedTabId];
}

TabLayer.prototype.autoSelectTab = function() {
        var cookieTab = this._getCookie(this.id+"_selectedTab");
        //alert(cookieTab);
        if(this.tabs[cookieTab]!=null) {
            this.selectTab(cookieTab);
                return;
        }
        //lets get the first one then
        for(elm in this.tabs) {
                this.selectTab(elm);
                return;
        }
}

TabLayer.prototype.resetAutoSelectTab = function()  {
   this._setCookie(this.id+"_selectedTab",'');
}
TabLayer.prototype.hideTab= function(tabId) {
        document.getElementById(tabId).style.display="none";
        var contentRef = this._getContent(tabId);
        if(contentRef != null) {
                contentRef.style.display="none";
        }
        this.realignTabs();
}

TabLayer.prototype.remeberSelectedTab = function(bool) {
        this.rememberSelectedTab = bool;
}

TabLayer.prototype.realignTabs = function() {
    var tabCount=0;
    var visibleTabs=0;
    var lastYPos = 0;
    for(elm in this.tabs) {

        var tab = document.getElementById(elm);
        if(tab != null && tab.style.display != 'none') {

            if( lastYPos == 0) 
                lastYPos = this._findPosY(tab);

            if(this._findPosY(tab) > lastYPos) {
                lastYPos = this._findPosY(tab);
                visibleTabs =0;
            }

            tab.style.left = this.tabOverlap*visibleTabs;
            visibleTabs++;
        }
    }
}

//Code from http://www.quirksmode.org/js/findpos.html
TabLayer.prototype._findPosY = function(obj) {
    var curtop = 0;
    if (obj.offsetParent) {
        while (obj.offsetParent) {
            curtop += obj.offsetTop
                obj = obj.offsetParent;
        }
    }
    else if (obj.y)
    curtop += obj.y;
    return curtop;
}

//Code from http://www.quirksmode.org/js/findpos.html
TabLayer.prototype._findPosX = function(obj) {
    var curleft = 0;
    if (obj.offsetParent) {
        while (obj.offsetParent) {
            curleft += obj.offsetLeft
                obj = obj.offsetParent;
        }
    }
    else if (obj.x)
    curleft += obj.x;
    return curleft;
}




TabLayer.prototype._getCookie = function(Name) {          
        var search = Name + "="          
        if (document.cookie.length > 0) { // if there are any cookies                   
                offset = document.cookie.indexOf(search)                    
                if (offset != -1) { // if cookie exists
                        offset += search.length // set index of beginning of value
                        end = document.cookie.indexOf(";", offset)           // set index of end of cookie value
                        if (end == -1)
                        end = document.cookie.length
                        return unescape(document.cookie.substring(offset, end))                    
                }           
        }
}       

TabLayer.prototype._setCookie = function(name, value, expires, path, domain, secure) {
        var curCookie = name + "=" + escape(value) +
        ((expires) ? "; expires=" + expires.toGMTString() : "") +
        ((path) ? "; path=" + path : "; path=/") +
      ((domain) ? "; domain=" + domain : "") +
        ((secure) ? "; secure" : "");
        document.cookie = curCookie;
}

TabLayer.prototype.setWidth = function(width) {
        document.getElementById(this.id+"Row").style.width="100%";
        document.getElementById(this.id+"Body").style.width="100%";
        document.getElementById(this.id).style.width=width;
}

TabLayer.prototype.setHeight = function(height) {
        //document.getElementById(this.id+"Row").style.height="100%";
        //document.getElementById(this.id+"Body").style.height="100%";
        document.getElementById(this.id).style.height=height;
}

TabLayer.prototype.setSize = function(width,height) {
    if(width!=null)
        this.setWidth(width);
    if(height!=null)
        this.setHeight(height);
}


/**
 * TabItem class
 */


function ___selectTab(tabLayerId,tabId) {
        ___tabLayers[tabLayerId].selectTab(tabId);
}

function ___closeCurrentTab(tabLayerId) {
        ___tabLayers[tabLayerId].closeCurrentTab(tabLayerId);
}

function TabItem(parent,tabId, activeClassName, inActiveClassName) {
        this.parent = parent;
        this.id = tabId;
        this.activeTabCSSClassName = activeClassName;
        this.inActiveTabCSSClassName = inActiveClassName;
        this.isCloseAble = true;
        return this;
}

// used to set invidual tabs for each tab, if this is not set then default is used
TabItem.prototype.setActiveTabCSSClassName = function(CSSClassName) {
        this.activeTabCSSClassName = CSSClassName;
        
}

// used to set invidual tabs for each tab, if this is not set then default is used
TabItem.prototype.setInActiveTabCSSClassName = function(CSSClassName) {
        this.inActiveTabCSSClassName = CSSClassName;
}



TabItem.prototype.execPreActions = function() {
        this._execActions(this.preActions);
}

TabItem.prototype.execPostActions = function() {
        this._execActions(this.postActions);
}

TabItem.prototype._execActions = function(actions) {
        
        if(actions == null || actions.length==0) {
                return;
        }
        for(elm in actions) {
                try {
                        eval(actions[elm]);
                } 
                catch(e) {
                        return false;
                }
        }
        return true;
}

TabItem.prototype.setTitle = function(title) {
        document.getElementById(this.id+"_title").innerHTML=title;
}

TabItem.prototype.getTitle = function() {
        return document.getElementById(this.id+"_title").innerHTML;
}

TabItem.prototype.setCloseAble = function(bool) {
    var closeBtn= document.getElementById(this.id+"_closeButton").style.display=(bool?'':'none');
    this.isCloseAble = bool;
}

TabItem.prototype.getCloseAble = function() {

    return this.isCloseAble;
}

TabItem.prototype.addPreAction = function(method) {
        if(this.preActions == null) {
                this.preActions = new Array();
        }
        this.preActions.push(method);
}

TabItem.prototype.addPostAction = function(method) {
        if(this.postActions == null) {
                this.postActions = new Array();
        }
        this.postActions.push(method);
}

TabItem.prototype.setContent = function(content) {
        this.parent._setContent(this.id,content);
}

TabItem.prototype.getContent = function() {
        return this.parent._getContent(this.id);
}


TabItem.prototype.select = function() {
        this.parent.selectTab(this.id);
}

TabItem.prototype.setContentFromElement = function(contentId) {
        this.parent.setContentFromElement(this.id,contentId);
}

TabItem.prototype.hide = function() {
        this.parent.hideTab(this.id);
}

TabItem.prototype.close = function() {
        this.parent.closeTab(this.id);
}
