(function(){
  if (($('body.listens.index').length) || $('body.stations.create').length) {

    if ($('#firstSongNotificationModal').attr('data-first-visit') === 'true') {
      $('#firstSongNotificationModal').foundation('reveal', 'open');
    } 

  }
}());