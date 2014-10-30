(function(){
  if (($('body.listens').length) || 
    ($('body.stations.create').length)) {

    if ($('#firstSongNotificationModal').attr('data-first-visit') === 'true') {
      $('#firstSongNotificationModal').foundation('reveal', 'open');
    }

    // construct initialization obj for stationPlayer
    var obj = {};
    obj.audioQueue = gon.audioQueue;
    obj.stationId = gon.station_id;
    obj.scheduleId = gon.schedule_id;

    // create the station and start it
    var player = new StationPlayer(obj);
    player.startPlayer();

  }

}());