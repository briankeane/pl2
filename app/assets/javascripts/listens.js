(function(){
  if (($('body.stations.index').length) || 
    ($('body.stations.create').length)) {

    if ($('#firstSongNotificationModal').attr('data-first-visit') === 'true') {
      $('#firstSongNotificationModal').foundation('reveal', 'open');
    }

    // set up stations to continually get nowPlaying
    for (list in gon.stationLists) {
      if(gon.stationLists.hasOwnProperty(list)) {
        for (station in list) {
          if (gon.stationLists[list].hasOwnProperty(station)) {
            getNowPlaying(gon.stationLists[list][station].id, function(result) {

            });
          }
        }
      }
    };

  }

}());