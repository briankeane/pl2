

(function(){
  var filepickerApiKey = $('.filepicker_info').attr('data-api-key');
  
  filepicker.setKey(filepickerApiKey);

  $(document).foundation('alert','events');

  $('#filepicker').on('change', function(e) {
    var uploadedSongs = e.originalEvent.fpfiles;

    console.log(e);


    for (var i=0; i<uploadedSongs.length; i++) {
      var html = '<div data-alert data-key="' + uploadedSongs[i]["key"] + 
                  '" class="alert-box"><div class="filename">' + 
                  uploadedSongs[i]["filename"] + 
                  '</div><div class="status">processing....</div>' +
                  '<img src="/images/processing_icon.gif" class="processing-icon" /></div>';
      $('#uploaded-song-list').append(html);
    }


    for (var i=0; i<uploadedSongs.length; i++) {
      $.ajax({
          type: "POST",
          dataType: "json",
          url: '/upload/process_song',
          contentType: 'application/json',
          data: JSON.stringify(uploadedSongs[i]),
          success: function(result) {
            console.log(result);
            var correspondingDiv = '*[data-key="' + result.table.key + '"]'
            
            if (result.table.error === "song_already_exists") {
              $(correspondingDiv).addClass("success");
              $(correspondingDiv + ' .status').text('Already Uploaded');
              $(correspondingDiv).prepend('<a href="#" class="close">&times;</a>');
              $(correspondingDiv + ' .processing-icon').addClass('hide');
            } else if ((result.table.error === "no_title_in_id3_tags") ||
                      (result.table.error === "no_artist_in_id3_tags") ||
                      (result.table.error === "no_echonest_match_found")) {
              $(correspondingDiv).addClass("error");
              $(correspondingDiv + ' .status').text('Info Needed');
              $(correspondingDiv + ' .status').addClass('tiny button');
              $(correspondingDiv + ' .status').attr("data-error", result.table.error);
              $(correspondingDiv + ' .status').attr("data-title", result.table.id3_tags.title);
              $(correspondingDiv + ' .status').attr("data-artist", result.table.id3_tags.artist);
              $(correspondingDiv + ' .status').attr("data-album", result.table.id3_tags.album);
              $(correspondingDiv + ' .processing-icon').addClass('hide');
            }
          },
          error : function(error) {
            $('#songInfoModal').foundation('reveal', 'open');
            console.log(error);
          }
      });

    }  //endfor

    console.log(e);
  });
  
  $('#uploaded-song-list').on('click', '.status.tiny.button', function(event) {
    console.log(event);
    if (($(this).attr('data-error') === 'no_title_in_id3_tags') ||
          ($(this).attr('data-error') === 'no_artist_in_id3_tags')) {
      $('#songInfoModal #title').val($(this).attr('data-title'));
      $('#songInfoModal #artist').val($(this).attr('data-artist'));
      $('#songInfoModal #album').val($(this).attr('data-album'));
      $('#songInfoModal').foundation('reveal', 'open');
    }
  });

  $('.choose').click(function(e) {
    filepicker.pick({ mimetype: 'audio/*'}, 
                      {}, 
                    function(InkBlobs) { alert('done'); console.log(stringify(InkBlobs));
                    });
  });


  $('#searchbox').keyup(function() {
    var allListElements = $('li');
    var fullList = $('#catalog-list li');
    var searchString = $('#searchbox').val().toLowerCase();

    for (var i=0; i<fullList.length; i++) {
      var attr = fullList.eq(i).attr('data-searchString');
      if  (typeof attr !== 'undefined' && attr !== false) {
        var targetString = fullList.eq(i).attr("data-searchString").toLowerCase();

        if (targetString.indexOf(searchString) == -1) {
          fullList.eq(i).hide();
        } else {
          fullList.eq(i).show();
        }

      }
    }

  });

})();
