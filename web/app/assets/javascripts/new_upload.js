

(function(){
  var filepickerApiKey = $('.filepicker_info').attr('data-api-key');
  
  filepicker.setKey(filepickerApiKey);

  $(document).foundation('alert','events');

  $('#filepicker').on('change', function(e) {
    var uploadedSongs = e.originalEvent.fpfiles;

    console.log(e);


    for (var i=0; i<uploadedSongs.length; i++) {
      var html = '<div data-alert data-key="' + uploadedSongs[i]["key"] + '" class="alert-box"><div class="filename">' + uploadedSongs[i]["filename"] + '</div><div class="status">processing....</div>'
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
            if (result.table.error === "song_already_exists") {
              var correspondingDiv = '*[data-key="' + result.table.key + '"]'
              $(correspondingDiv).addClass("alert");
              $(correspondingDiv + ' .status').text('Already Uploaded');
              $(correspondingDiv).append('<a href="#" class="close">&times;</a>');
            } else {
              $('#songInfoModal').foundation('reveal', 'open');
            }
          },
          error : function(error) {
            console.log(error);
          }
        });

    }

    console.log(e);
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
