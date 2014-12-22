(function(){
  if ($('body.stations.show').length) {
    
    var updateNowPlaying = function() {
      // clear the previous class
      $('#nowPlayingList .nowPlaying').removeClass('song');
      $('#nowPlayingList .nowPlaying').removeClass('commercialBlock');
      $('#nowPlayingList .nowPlaying').removeClass('commentary');
      $('#nowPlayingList .nowPlaying .songId').removeClass('');
      $('#nowPlayingList .nowPlaying .addToMyStationButton').remove();
      
      // update the class and info 
      if (gon.player.audioQueue[0].type === 'Song') {
        $('#nowPlayingList .nowPlaying').addClass('song');
        $('#nowPlayingList .nowPlaying .title').text(gon.player.audioQueue[0].title);
        $('#nowPlayingList .nowPlaying .artist').text(gon.player.audioQueue[0].artist);
        $('#nowPlayingList .nowPlaying').attr('data-songId', gon.player.audioQueue[0].id);

        // add button
        var html = '<button class="addToMyStationButton">Add Song To My Station</button>';
        $('#nowPlayingList .nowPlaying .artist').after(html);
        $('#nowPlayingList .nowPlaying .addToMyStationButton').attr('data-songId', gon.player.audioQueue[0].id);

        if (gon.player.audioQueue[0].id in gon.currentStation.spins_per_week) {
          $('#nowPlayingList .nowPlaying .addToMyStationButton').addClass('disabled');
          $('#nowPlayingList .nowPlaying .addToMyStationButton').text('Song Added');
        }

      } else if (gon.player.audioQueue[0].type === 'Commentary') {
        $('#nowPlayingList .nowPlaying').addClass('commentary');
        $('#nowPlayingList .nowPlaying .title').text('Commentary');
        $('#nowPlayingList .nowPlaying .artist').text('');
      } else if (gon.player.audioQueue[0].type === 'CommercialBlock') {
        $('#nowPlayingList .nowPlaying').addClass('commercialBlock');
        $('#nowPlayingList .nowPlaying .title').text('Commercial Block');
        $('#nowPlayingList .nowPlaying .artist').text('');
      }
    };

    var advanceSongHistory = function() {
      var html = '<li class="song">' + 
                    '<span class="title">' + gon.player.justPlayed.title + '</span>';

      
      if (gon.player.justPlayed.audio_block_id in gon.currentStation.spins_per_week) {
        html = html + '<button class="addToMyStationButton disabled">Song Added</button>';
      } else {
        html = html + '<button class="addToMyStationButton">Add Song To My Station</button>';
      }
      
      html = html + '<span class="artist">' + gon.player.justPlayed.artist + '</span>' + 
              '</li>';

      $('#songHistoryList li:first').before(html);
      $('#songHistoryList li:last').remove();
    };

    // set response for nowplaying
    $(document).on('playerStarted', function() {
      updateNowPlaying();
    });

    $(document).on('spinAdvanced', function() {
      updateNowPlaying();
      if (gon.player.justPlayed.type === 'Song') {
        advanceSongHistory();
      }
    });

    // create and start player
    console.log(navigator.sayswho.split(" ")[0]);
    if (navigator.sayswho.split(" ")[0] === 'Chrome') {
      gon.player = new webAudioStationPlayer(gon);
    } else {
      gon.player = new StationPlayer(gon);
    }
    gon.player.startPlayer();
  }
  
})();
