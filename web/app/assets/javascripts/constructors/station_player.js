var StationPlayer = function(attrs) {
  
  // store necessary stuff
  var musicStarted = false;
  this.scheduleId = attrs.scheduleId;
  this.stationId = attrs.stationId;
  this.audioQueue = attrs.audioQueue;
  this.muted = false;
  var self = this;

  var getSpinByCurrentPosition = function(currentPosition, callback) {
    var getSpinInfo = {};
    getSpinInfo.last_current_position = parseInt($('#schedule-list').attr('data-lastCurrentPosition'));
    getSpinInfo.current_position = currentPosition;
    getSpinInfo.station_id = self.stationId;
    getSpinInfo.schedule_id = self.scheduleId;

    $.ajax({
          type: 'GET',
          dataType: 'json',
          url: '/schedules/get_spin_by_current_position',
          contentType: 'application/json',
          data: getSpinInfo,
          success: callback
    });
  }

  var advanceSpin = function() {
    
    console.log('advancing spin...')
    // advance audioQueue
    self.audioQueue.shift();
    self.audioQueue[0].audio.play();
    // create callback for ajax request
    var updateQueue = function(result) {
      console.log(result);
      var newSong = {};

      // reformat response for js
      result.artist = result.audio_block.artist;
      result.title = result.audio_block.title;
      result.audio = new Audio(result.key);

      self.audioQueue.push(result);

      // if commercials follow that spin
      if (result["commercials_follow?"]) {
        self.audioQueue.push(getCommercialBlock(result.currentPosition));
      }
      return result;
    }
    
    // get the newest spin
    getSpinByCurrentPosition(self.audioQueue[self.audioQueue.length-1].currentPosition + 1, updateQueue);
    $(document).trigger('spinAdvanced');
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

}
