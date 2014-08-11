_progressBarCount=0;
_progressBarDefaultName="progressBar";
_progressBarDefaultClassName="progressbar";
_progressBarDefaultAniWidth = 50;
_progressBarDefaultAniSpeed = 10;
_progressBarDefaultAniStep  = 2;
_progressBarInstances = Array();

function ProgressBar(divId,doc) {
  _progressBarCount++;
  if(doc==null) {this.doc = document;}
  else {this.doc = doc;}
  if(divId!=null)
    this.div = this.doc.getElementById(divId);
  if(this.div == null) {
    this.div = this.doc.createElement("DIV");
    this.div.id=(divId==null?_progressBarDefaultName+'_'+_progressBarCount:divId);
    this.doc.body.appendChild(this.div);
  }
  this.div.className=_progressBarDefaultClassName;
  
  /* Setting up the bar */
  this.bar = this.doc.getElementById(this.div.id+"_bar");
  if(this.bar == null) {
    this.bar = this.doc.createElement("DIV");
    this.bar.id=this.div.id+"_bar";
    this.div.appendChild(this.bar);
  }
  this.bar.style.position="relative";
  this.bar.style.width="0px";
  this.bar.style.height="100%";//(this.div.offsetHeight-2)+"px";
  
  // this.bar.innerHTML="s";
  
  _progressBarInstances[this.div.id] = this;
}

ProgressBar.prototype.setRange = function(fromValue, toValue) {
  this.fromValue=fromValue;
  this.toValue=toValue;
  this.mode="percentage";
}

ProgressBar.prototype.increment = function(step) {
  if(this.finish == true) return;
  var percent = step / this.toValue ;
  this.bar.style.width=(percent*this.div.offsetWidth-2)+"px";
  
  if(this.barShowText) {
    this.bar.innerHTML = "<nobr>"+step+" / "+this.toValue+"("+percent*100+"%)</nobr>";
  }
  if(percent >=1) {
    this.finish=true;
    return ;
  }
}


ProgressBar.prototype.aniMode = function() {
  this.mode="animode";
}

ProgressBar.prototype.start = function() {
  if(this.isPaused) {
    this.isPaused=false;
  }
  else if(this.isRunning) {
    return;
  }
  else {
    this.reset()
    this.isRunning = true;
  }
  
  this._animate();
}

ProgressBar.prototype._animate = function() {
  
  if(this.isRunning) {
    
    // window.status=(this.currLeft+this.bar.offsetWidth)+">="+(this.div.offsetWidth-2);
    if(!this.isInc && this.currLeft <=0 && !this.goLeft) {
      this.currWidth-=_progressBarDefaultAniStep;
      this.bar.style.width=this.currWidth+"px";
      if(this.currWidth<=0) {
        this.goLeft=true;
        this.isInc = true;
      }
    }
    else if(!this.isInc && this.currWidth / (this.div.offsetWidth-2)*100 > _progressBarDefaultAniWidth) {
      this.currLeft-=_progressBarDefaultAniStep;
      this.bar.style.left=this.currLeft+"px";
    }
    else if(this.currLeft+this.bar.offsetWidth>=this.div.offsetWidth-2) {
      this.goLeft=false;
      if(this.bar.offsetWidth<=0) {
        this.isInc=false;
      }
      this.currLeft+=(this.isInc?_progressBarDefaultAniStep:-1*_progressBarDefaultAniStep);
      this.bar.style.left=this.currLeft+"px";
      this.currWidth+=(this.isInc?-1*_progressBarDefaultAniStep:_progressBarDefaultAniStep);
      this.bar.style.width=this.currWidth+"px";
    }
    else if(this.isInc && (this.currWidth / (this.div.offsetWidth-2)*100 < _progressBarDefaultAniWidth)) {
      this.currWidth+=_progressBarDefaultAniStep;
      this.bar.style.width=this.currWidth+"px";
    }
    else if(this.goLeft) {
      this.currLeft+=_progressBarDefaultAniStep;
      this.bar.style.left=this.currLeft+"px";
    }
    
    if(this.isRunning && !this.isPaused)
      setTimeout(new Function("_progressBarAnimate('"+this.div.id+"')"),_progressBarDefaultAniSpeed);
  }
}

function _progressBarAnimate(id) {
  _progressBarInstances[id]._animate();
}

ProgressBar.prototype.stop = function() {
  this.isRunning = false;
  this.currLeft=0;
  this.currWidth=0;
  this.bar.style.left=this.currLeft+"px";
  this.bar.style.width=(parseInt(this.div.offsetWidth)-2)+"px";
  this.goLeft=true;
  this.isInc = true;
  this.isPaused=false;
}

ProgressBar.prototype.pause = function() {
  this.isPaused = true;
  
}

ProgressBar.prototype.reset = function() {
  this.isPaused = false;
  this.currLeft=0;
  this.currWidth=0;
  this.bar.style.left=this.currLeft+"px";
  this.bar.style.width=this.currWidth+"px";
  this.goLeft=true;
  this.isInc = true;
  this.isRunning = false;
}

ProgressBar.prototype.setText = function(text) {
  //this.div.innerHTML=text;
}

ProgressBar.prototype.delText = function() {
  //this.div.innerHTML='';
}
