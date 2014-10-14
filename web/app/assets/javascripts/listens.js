(function(){
  if ($('body.listens.index').length) {

    if ($('#firstSongNotificationModal').attr('data-first-visit') === true) {
      $('#firstSongNotificationModal').foundation('reveal', 'open');
    }

  }
}());