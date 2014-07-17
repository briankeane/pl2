(function(){
  
  $('#getUserInfoModal').foundation('reveal', 'open');
  $('#heavy').sortable();
  $('#all-songs-list').sortable({ connectWith: ["#heavy", "#medium", "#light"],
                            dropOnEmpty: true });
  $('#heavy').sortable({ connectWith: ["#all-songs-list", "#medium", "#light"],
                          dropOnEmpty: true,
                          receive: function(event, ui) {
                              addToRotation(event, ui);
                            },
                            remove: function(event, ui) {
                              deleteFromRotation(event, ui)
                            }  });
  $('#medium').sortable({ connectWith: ["#heavy", "#all-songs-list", "#light"],
                            dropOnEmpty: true,
                            receive: function(event, ui) {
                              addToRotation(event, ui);
                            },
                            remove: function(event, ui) {
                              deleteFromRotation(event, ui)
                            }
                        });
  $('#light').sortable({   connectWith: ["#heavy", "#medium", "#all-songs-list"],
                            dropOnEmpty: true,

                            receive: function(event, ui) {
                              addToRotation(event, ui);
                            },

                            remove: function(event, ui) {
                              deleteFromRotation(event, ui)
                            }

                            });
  $('#searchText').keyup(function() {
    var allListElements = $('li');
    var fullList = $('#all-songs-list li');
    var searchString = $('#searchText').val().toLowerCase();

    for (var i=0; i<fullList.length; i++) {
      var attr = fullList.eq(i).attr('data-searchString');
      if  (typeof attr !== 'undefined' && attr !== false) {
        var targetString = fullList.eq(i).attr("data-searchString").toLowerCase();

        if (targetString.indexOf(searchString) == -1) {
          fullList.eq(i).hide();
        } else {
          fullList.eq(i).show();
        }

      }  // endif
    }  //endfor

  });

  $('#random').on('click', function() {
    while ($('#heavy li').length < 13) {
      var allSongsList = $('#all-songs-list li');
      moveAnimate(allSongsList.eq(Math.floor((Math.random()) * allSongsList.length)), $('#heavy'));
    }

    while ($('#medium li').length < 30) {
      var allSongsList = $('#all-songs-list li');
      moveAnimate(allSongsList.eq(Math.floor((Math.random()) * allSongsList.length)), $('#medium'));
    }

    while ($('#light li').length < 13) {
      var allSongsList = $('#all-songs-list li');
      moveAnimate(allSongsList.eq(Math.floor((Math.random()) * allSongsList.length)), $('#light'));
    }
  });

  $('#create').on('click', function() {
    if ($('#heavy li').length < 13) {
      alert('Please add ' + ((13 - $('#heavy li').length)).toString() + ' songs to the heavy bin.');
    } else if ($('#medium li').length < 13) {
      alert('Please add ' + ((29 - $('#medium li').length)).toString() + ' songs to the medium bin.');
    } else if ($('#light li').length < 5) {
      alert('Please add ' + ((13 - $('#light li').length)).toString() + ' songs to the light bin.');
    } else {

      var heavyElements = $('#heavy li')
      var mediumElements = $('#heavy li')
      var lightElements = $('#heavy li')
      var heavyIds = [];
      var mediumIds = [];
      var lightIds = [];

      for (var i in heavyElements) {
        heavyIds.push(heavyElements.eq(i).attr('data-id'));
      }
      for (var i in mediumElements) {
        mediumIds.push(mediumElements.eq(i).attr('data-id'));
      }
      for (var i in lightElements) {
        lightIds.push(lightElements.eq(i).attr('data-id'));
      }

      createStationInfo = {
        heavy: heavyIds,
        medium: mediumIds,
        light: lightIds
      };



      $.ajax({
        type: "POST",
        dataType: "json",
        url: '/station/create',
        contentType: 'application/json',
        data: JSON.stringify(createStationInfo),
        success: function(obj) {
          window.location = '/dj_booth';
        },
        error : function(error) {
          console.log(error);
        }
      });

    } //endif
  });  //end create event

})();