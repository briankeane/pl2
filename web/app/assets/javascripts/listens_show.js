(function(){
  if ($('body.listens.show').length) {
  
    var updateNowPlaying = function() {
      // clear the previous class
      $('#nowPlayingList .nowPlaying').removeClass('song');
      $('#nowPlayingList .nowPlaying').removeClass('commercialBlock');
      $('#nowPlayingList .nowPlaying').removeClass('commentary');
      
      // update the class and info
      if (player.audioQueue[0].type === 'Song') {
        $('#nowPlayingList .nowPlaying').addClass('song');
        $('#nowPlayingList .nowPlaying .title').text(player.audioQueue[0].title);
        $('#nowPlayingList .nowPlaying .artist').text(player.audioQueue[0].artist);
      } else if (player.audioQueue[0].type === 'Commentary') {
        $('#nowPlayingList .nowPlaying').addClass('commentary');
        $('#nowPlayingList .nowPlaying .title').text('Commentary');
        $('#nowPlayingList .nowPlaying .artist').text('');
      } else if (player.audioQueue.type === 'CommercialBlock') {
        $('#nowPlayingList .nowPlaying').addClass('commercialBlock');
        $('#nowPlayingList .nowPlaying .title').text('Commercial Block');
        $('#nowPlayingList .nowPlaying .artist').text('');
      }
    }
    
    // construct initialization obj for stationPlayer
    var obj = {};
    obj.audioQueue = gon.audioQueue;
    obj.stationId = gon.station_id;
    obj.scheduleId = gon.schedule_id;

    // set response for nowplaying
    $(document).on('playerStarted', function() {
      updateNowPlaying();
    });

    $(document).on('spinAdvanced', function() {
      updateNowPlaying();
    });

    // create the station and start it
    var player = new StationPlayer(obj);
    player.startPlayer();

  }
  
})();
