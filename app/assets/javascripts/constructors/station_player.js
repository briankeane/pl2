var StationPlayer = function(attrs) {
  
  // store necessary stuff
  var musicStarted = false;
  this.stationId = attrs.stationId;
  this.stationId = attrs.stationId;
  this.audioQueue = attrs.audioQueue;
  this.muted = false;
  var self = this;

  var getCommercialBlockForBroadcast = function(currentPosition) {
    
    var callback = function(result) {
      result.audio = new Audio(result.key);
      result.audio.muted = self.muted;
      self.audioQueue.push(result);
    }

    var spinInfo = {}
    spinInfo.currentPosition = currentPosition;
    spinInfo.stationId = self.stationId;  
    
    $.ajax({
        type: 'GET',
        dataType: 'json',
        url: '/stations/get_commercial_block_for_broadcast',
        contentType: 'application/json',
        data: spinInfo,
        success: callback
    });
  }

  var advanceSpin = function() {
    console.log('advancing spin...')

    // advance audioQueue
    self.justPlayed = self.audioQueue.shift();
    self.audioQueue[0].audio.play();

    // set the next advance
    var msTillAdvanceSpin = (self.audioQueue[1].airtime_in_ms - Date.now());
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);

    if (self.audioQueue.length<4) { 
      
      // create callback for ajax request
      var updateQueue = function(result) {
        console.log(result);
        var newSong = {};

        // reformat response for js
        if (result.type != 'CommercialBlock') {
          result.artist = result.audio_block.artist;
          result.title = result.audio_block.title;
        }
        result.audio = new Audio(result.key);
        result.audio.muted = self.muted;

        self.audioQueue.push(result);

        // if commercials follow that spin
        if (result["commercials_follow?"]) {
          getCommercialBlockForBroadcast(result.currentPosition);
        }
        return result;
      }
        
      // get the newest spin
      var spinInfo = {};
      spinInfo.currentPosition = self.audioQueue[self.audioQueue.length - 1].currentPosition + 1;
      spinInfo.lastCurrentPosition = spinInfo.currentPosition;
      spinInfo.stationId = self.stationId;
      
      getSpinByCurrentPosition(spinInfo, updateQueue);
      
      $(document).trigger('spinAdvanced');
    }
  }

  this.startPlayer = function() {
    // load the queue
    for (var i=0;i<self.audioQueue.length;i++) {
      self.audioQueue[i].audio = new Audio(self.audioQueue[i].key);
    }

    // set the next advance
    var msTillAdvanceSpin = (self.audioQueue[1].airtime_in_ms - Date.now());
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);

    // start the first song in the proper place
    self.audioQueue[0].audio.addEventListener('canplaythrough', function() {
      if (!musicStarted) {   // so it only does this once
        musicStarted = true;

        var t = setTimeout(function() {
          self.audioQueue[0].audio.play();
          self.audioQueue[0].audio.currentTime = (Date.now() - self.audioQueue[0].airtime_in_ms)/1000;

        }, 5000);
      } // endif 1st time
    });

    $(document).trigger('playerStarted');
  } // end this.startPlayer

  this.nowPlaying = function() {
    return self.audioQueue[0];
  }

  this.mute = function() {
    self.muted = !self.muted;
    for(var i=0;i<self.audioQueue.length;i++) {
      self.audioQueue[i].audio.muted = self.muted;
    }
  }
}
