(function(){
  if (($('body.stations.index').length) || 
    ($('body.stations.create').length)) {

    if ($('#firstSongNotificationModal').attr('data-first-visit') === 'true') {
      $('#firstSongNotificationModal').foundation('reveal', 'open');
    }

    var updateStationSquare = function(spin) {
      var spinLiSelector = '*[data-id="' + spin.station_id +'"]'
      if (spin.is_commercial_block) {
        $(spinLiSelector).find('.now-playing-title').text('Commercial Block');
        $(spinLiSelector).find('.now-playing-artist').text('');
      } else {
      $(spinLiSelector).find('.now-playing-title').text(spin.audio_block.title);
      $(spinLiSelector).find('.now-playing-artist').text(spin.audio_block.artist);
      }
    }

    var updateNowPlayingCallback = function(spin) {
      // update station-square
      updateStationSquare(spin);

      // schedule next lookup
      var endTime = spin.airtime_in_ms + spin.audio_block.duration;
      var msTillAdvance = (endTime - Date.now());

      // if advance has already passed, update again now
      if (msTillAdvance < 0) {
        console.log('msTillAdvance < 0!');
        console.log('endtime: ' + new Date(endTime));
        console.log('now: ' + new Date());
        getNowPlaying(spin.station_id, updateNowPlayingCallback);
      } else {
        setTimeout(function() { 
          getNowPlaying(spin.station_id, updateNowPlayingCallback); 
        }, msTillAdvance);
      }
    }

    // set up stations to continually get nowPlaying
    for (list in gon.stationLists) {
      if(gon.stationLists.hasOwnProperty(list)) {
        for (station in list) {
          if (gon.stationLists[list].hasOwnProperty(station)) {
            getNowPlaying(gon.stationLists[list][station].id, updateNowPlayingCallback);            
          }
        }
      }
    };



  }


}());