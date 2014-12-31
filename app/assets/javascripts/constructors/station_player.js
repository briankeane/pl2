var StationPlayer = function(attrs) {
  
  // store necessary stuff
  var musicStarted = false;
  this.stationId = attrs.stationId;
  this.audioQueue = attrs.audioQueue;
  this.muted = false;
  var self = this;

  var getCommercialBlockForBroadcast = function(currentPosition) {
    
    var callback = function(result) {
      result.audio = new Audio(result.key);
      result.audio.muted = self.muted;
      self.audioQueue.push(result);
    };

    var spinInfo = {};
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
  };

  var advanceSpin = function() {
    console.log('advancing spin...');

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
      };
        
      // get the newest spin
      var spinInfo = {};
      spinInfo.currentPosition = self.audioQueue[self.audioQueue.length - 1].currentPosition + 1;
      spinInfo.lastCurrentPosition = spinInfo.currentPosition;
      spinInfo.stationId = self.stationId;
      
      getSpinByCurrentPosition(spinInfo, updateQueue);
      
      // report the listen
      self.reportListen();
      $(document).trigger('spinAdvanced');
    }
  };
  this.reportListen = function() {
        $.ajax({
        type: 'PUT',
        dataType: 'json',
        url: '/users/report_listener',
        contentType: 'application/json',
        data: JSON.stringify({ "stationId": this.stationId }),
        success: function() {
          console.log('listen reported');
        }
    });
  };

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
          self.reportListen();
          $(document).trigger('playerStarted');

        }, 5000);
      } // endif 1st time
    });

  }; // end this.startPlayer

  this.nowPlaying = function() {
    return self.audioQueue[0];
  };

  this.mute = function() {
    if (!self.muted) {
      self.muted = true;
      for(var i=0;i<self.audioQueue.length;i++) {
        self.audioQueue[i].audio.muted = true;
      }
    }
  };

  this.unMute = function() {
    if (self.muted) {
      self.muted = false;
      for(var i=0;i<self.audioQueue.length;i++) {
        self.audioQueue[i].audio.muted = false;
      }
    }
  };
};


var webAudioStationPlayer = function(attrs) {
  // store necessary stuff
  var musicStarted = false;
  this.stationId = attrs.stationId;
  this.audioQueue = attrs.audioQueue;
  this.muted = false;
  this.volumeLevel = 1.0;
  this.context = new AudioContext();
  this.gainNode = this.context.createGain();
  this.gainNode.connect(this.context.destination);
  var self = this;

  var getCommercialBlockForBroadcast = function(currentPosition) {
    
    var callback = function(result) {
      self.audioQueue.push(result);
      loadAudio(self.audioQueue[self.audioQueue.length - 1].key);
    };

    var spinInfo = {};
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
  };

  var updateAudioQueue = function() {
      
    // create callback for ajax request
    var callback = function(result) {
      console.log(result);
      var newSong = {};

      // reformat response for js
      if (result.type != 'CommercialBlock') {
        result.artist = result.audio_block.artist;
        result.title = result.audio_block.title;
      }

      self.audioQueue.push(result);
      var index = self.audioQueue.length - 1;
      loadAudio(result.key);

      // if commercials follow that spin
      if (result["commercials_follow?"]) {
        getCommercialBlockForBroadcast(result.currentPosition);
      }
      
      // make recursive calls until audioQueue is filled
      if (self.audioQueue.length < 4) {
        updateAudioQueue();
      }
    };
      
    // get the newest spin
    var spinInfo = {};
    spinInfo.currentPosition = self.audioQueue[self.audioQueue.length - 1].currentPosition + 1;
    spinInfo.lastCurrentPosition = spinInfo.currentPosition;
    spinInfo.stationId = self.stationId;
    
    getSpinByCurrentPosition(spinInfo, callback);

  };

  var advanceSpin = function() {
    console.log('advancing spin...');

    if (!self.musicStarted) {
      return;
    }

    // advance audioQueue
    self.justPlayed = self.audioQueue.shift();

    self.audioQueue[0].source.start(0); 

    // grab the new songs if necessary
    if (self.audioQueue.length<3) {
      updateAudioQueue();
    }

    // set the next advance
    var msTillAdvanceSpin = (self.audioQueue[1].airtime_in_ms - Date.now());
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);

    // report the listen
    self.reportListen();

    $(document).trigger('spinAdvanced');
    
  };

  this.reportListen = function() {
        $.ajax({
        type: 'PUT',
        dataType: 'json',
        url: '/users/report_listener',
        contentType: 'application/json',
        data: JSON.stringify({ "stationId": this.stationId }),
        success: function() {
          console.log('listen reported');
        }
    });
  };

  this.startPlayer = function() {
    loadAudio(self.audioQueue[0].key);

    $(document).on('playerStarted', function() {    // once 1st song has been loaded
      for (var i=0; i<self.audioQueue.length; i++) {
        loadAudio(self.audioQueue[i].key);
      }
      
      var msTillAdvanceSpin = (self.audioQueue[1].airtime_in_ms - Date.now());
      setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);
    });

    // set the next advance

  }; // end this.startPlayer

  this.nowPlaying = function() {
    return self.audioQueue[0];
  };

  this.mute = function() {
    if (self.muted === false) {
      self.muted = true;
      self.gainNode.gain.value = 0;
    }
  };

  this.unMute = function() {
    if (self.muted === true) {
      self.muted = false;
      self.gainNode.gain.value = self.volumeLevel;
    }
  };

  function loadAudio(url) {
    var context = gon.player.context;
    var request = new XMLHttpRequest();
    request.open('Get', url, true);
    request.responseType = 'arraybuffer';

    // decode
    request.onload = function() {
      context.decodeAudioData(request.response, function(buffer) {
        var source = context.createBufferSource();
        source.buffer = buffer;
        source.connect(self.gainNode);
        for (var i=0; i<self.audioQueue.length; i++) {
          var foundAMatch = false;
          if (self.audioQueue[i].key === url) {
            foundAMatch = true;
            self.audioQueue[i].source = source;
            
            // if it's the first station spin, start it in the proper place
            if (!self.musicStarted) {

              // if it's still within the 1st spin's airtime
              if ((new Date() < self.audioQueue[1].airtime_in_ms)) {
                self.musicStarted = true;
                source.start(0,(Date.now() - self.audioQueue[0].airtime_in_ms)/1000);
                $(document).trigger('playerStarted');
              } else {   // advance time passed during loading
                
                self.justPlayed = self.audioQueue.shift();
                loadAudio(self.audioQueue[0].key);
                $(document).trigger('spinAdvanced');
              }
            }
          }
        }  //endfor
      });
    };
    request.send();
  }
};