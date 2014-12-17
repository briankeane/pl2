var StationPlayer = function(attrs) {
  
  // store necessary stuff
  var musicStarted = false;
  this.stationId = attrs.stationId;
  this.audioQueue = attrs.audioQueue;
  this.muted = false;
  var self = this;

  // get browser
  var context = new AudioContext();
  var browser = navigator.sayswho.split(" ")[0];

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

    if (browser != 'Chrome') {
    self.audioQueue[0].audio.play();
    } else {
      self.audioQueue[0].source.start(0);
    } 

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

        if (browser != "Chrome") {
          result.audio = new Audio(result.key);
        } else {
          loadSong(result.key, result.audio);
        }

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
  }

  this.startPlayer = function() {
    // load the queue

    for (var i=0;i<self.audioQueue.length;i++) {
      (function(i) {
        var callback = function(source, index) {
          self.audioQueue[index].source = source;
          if (index === 0) {
            debugger;
            self.audioQueue[0].source.start(0, (Date.now() - self.audioQueue[0].airtime_in_ms)/1000);
          }
          $(document).trigger('playerStarted');
        }

        // if (browser != 'Chrome') {
        //   self.audioQueue[i].audio = new Audio(self.audioQueue[i].key);
        // } else {
        //   loadSong(self.audioQueue[i].key, callback, i);
        // }
        loadSong(self.audioQueue[0].key, callback, 0);
      })(i);
    }

    // set the next advance
    var msTillAdvanceSpin = (self.audioQueue[1].airtime_in_ms - Date.now());
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);

    // start the first song in the proper place
    if (browser != 'Chrome') {
      self.audioQueue[0].audio.addEventListener('canplaythrough', function() {
        if (!musicStarted) {   // so it only does this once
          musicStarted = true;

          var t = setTimeout(function() {
            self.audioQueue[0].audio.play();
            self.audioQueue[0].audio.currentTime = (Date.now() - self.audioQueue[0].airtime_in_ms)/1000;
            self.reportListen();
            loadSong(self.audioQueue[0].key);

          }, 5000);
        } // endif 1st time
      });
    }

    $(document).trigger('playerStarted');
  }; // end this.startPlayer

  this.nowPlaying = function() {
    return self.audioQueue[0];
  };

  this.mute = function() {
    self.muted = !self.muted;
    for(var i=0;i<self.audioQueue.length;i++) {
      self.audioQueue[i].audio.muted = self.muted;
    }
  };

  function loadSong(url, callback, index) {
    var context = new AudioContext();
    var request = new XMLHttpRequest();
    request.open('Get', url, true);
    request.responseType = 'arraybuffer';

    // decode
    request.onload = function() {
      context.decodeAudioData(request.response, function(buffer) {
        var source = context.createBufferSource();
        source.buffer = buffer;
        source.connect(context.destination);
        callback(source, index);
      });
    }
    request.send();
  }

};
