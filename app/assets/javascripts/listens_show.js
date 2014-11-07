(function(){
  if ($('body.listens.show').length) {
  
    var updateNowPlaying = function() {
      // clear the previous class
      $('#nowPlayingList .nowPlaying').removeClass('song');
      $('#nowPlayingList .nowPlaying').removeClass('commercialBlock');
      $('#nowPlayingList .nowPlaying').removeClass('commentary');
      $('#nowPlayingList .nowPlaying .songId').removeClass('')
      $('#nowPlayingList .nowPlaying .addToMyStationButton').remove();
      
      // update the class and info 
      if (player.audioQueue[0].type === 'Song') {
        $('#nowPlayingList .nowPlaying').addClass('song');
        $('#nowPlayingList .nowPlaying .title').text(player.audioQueue[0].title);
        $('#nowPlayingList .nowPlaying .artist').text(player.audioQueue[0].artist);

        // add button
        var html = '<button class="addToMyStationButton">Add Song To My Station</button>';
        $('#nowPlayingList .nowPlaying .artist').after(html);
        $('#nowPlayingList .nowPlaying .addToMyStationButton').attr('data-songId', player.audioQueue[0].audio_block_id);

        if (player.audioQueue[0].audio_block_id in gon.current_station.spins_per_week) {
          $('#nowPlayingList .nowPlaying .addToMyStationButton').addClass('disabled');
          $('#nowPlayingList .nowPlaying .addToMyStationButton').text('Song Added');
        }

      } else if (player.audioQueue[0].type === 'Commentary') {
        $('#nowPlayingList .nowPlaying').addClass('commentary');
        $('#nowPlayingList .nowPlaying .title').text('Commentary');
        $('#nowPlayingList .nowPlaying .artist').text('');
      } else if (player.audioQueue[0].type === 'CommercialBlock') {
        $('#nowPlayingList .nowPlaying').addClass('commercialBlock');
        $('#nowPlayingList .nowPlaying .title').text('Commercial Block');
        $('#nowPlayingList .nowPlaying .artist').text('');
      }
    }

    var advanceSongHistory = function() {
      var html = '<li class="song">' + 
                    '<span class="title">' + player.justPlayed.title + '</span>';

      
      if (player.justPlayed.audio_block_id in gon.current_station.spins_per_week) {
        html = html + '<button class="addToMyStationButton disabled">Song Added</button>'
      } else {
        html = html + '<button class="addToMyStationButton">Add Song To My Station</button>'
      }
      
      html = html + '<span class="artist">' + player.justPlayed.artist + '</span>' + 
              '</li>'

      $('#songHistoryList li:first').before(html);
      $('#songHistoryList li:last').remove();
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
      if (player.justPlayed.type === 'Song') {
        advanceSongHistory();
      }
    });

    $(document).on('click', '.addToMyStationButton', function() {
      if (!$(this).hasClass('disabled')) {
        var songId = parseInt($(this).attr('data-songId'));
        createSpinPerWeekListItem({ id: songId,
                      spinFrequency: 'Medium' });
        $(this).addClass('disabled');
        $(this).text('Song Added');

        // edit the current_station object in the browser
        gon.current_station.spins_per_week[songId] = 17;
      }
    });

    // create the station and start it
    var player = new StationPlayer(obj);
    player.startPlayer();
  }
  
})();
