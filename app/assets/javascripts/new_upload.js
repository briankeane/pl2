(function(){
  if ($('body.uploads.new').length) { 
    var filepickerApiKey = $('.filepicker_info').attr('data-api-key');
    
    filepicker.setKey(filepickerApiKey);

    $(document).foundation('alert','events');

    $('#filepicker').on('change', function(e) {
      var uploadedSongs = e.originalEvent.fpfiles;

      console.log(e);


      for (var i=0; i<uploadedSongs.length; i++) {
        var html = '<div data-alert data-key="' + uploadedSongs[i].key + 
                    '" data-filename="' + uploadedSongs[i].filename + 
                    '" class="alert-box"><div class="filename">' + 
                    uploadedSongs[i].filename + 
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
              var correspondingDiv = '*[data-key="' + result.table.unprocessed_key + '"]';
              
              if (result.table.error === "song_already_exists") {
                $(correspondingDiv).attr("data-songId", result.table.song.id);
                markAsAlreadyUploaded(correspondingDiv);
              } else if ((result.table.error === "no_title_in_tags") ||
                        (result.table.error === "no_artist_in_tags") ||
                        (result.table.error === "no_echonest_match_found")) {
                $(correspondingDiv).addClass("error");
                $(correspondingDiv + ' .status').text('Info Needed');
                $(correspondingDiv + ' .status').addClass('tiny button');
                $(correspondingDiv).attr("data-error", result.table.error);
                $(correspondingDiv).attr("data-title", result.table.tags.title);
                $(correspondingDiv).attr("data-artist", result.table.tags.artist);
                $(correspondingDiv).attr("data-album", result.table.tags.album);
                $(correspondingDiv + ' .processing-icon').addClass('hide');
              } else if (result.table.error === 'file_is_encrypted') {
                $(correspondingDiv).addClass('error');
                $(correspondingDiv).prepend('<a href="#" class="close">&times;</a>');
                $(correspondingDiv + ' .status').text('Info Needed');
                $(correspondingDiv + ' .processing-icon').addClass('hide');
                $(correspondingDiv + ' .status').text('File is Encrypted');
              } else if (!result.table.error) {
                markAsAdded(correspondingDiv);
              }
            },
            error : function(error) {
              console.log(error);
            }
        });

      }  //endfor

      console.log(e);
    });
    
    $('#uploaded-song-list').on('click', '.status.tiny.button', function(event) {
      console.log(event);
    $('#songInfoModal').foundation('reveal', 'open');
    $('#songInfoModal #title').val($(this).parent().attr('data-title'));
    $('#songInfoModal #artist').val($(this).parent().attr('data-artist'));
    $('#songInfoModal #album').val($(this).parent().attr('data-album'));
    $('#songInfoModal').attr("data-key", $(this).parent().attr('data-key'));
    $('#songInfoModal').attr('data-filename', $(this).parent().attr('data-filename'));
    });

    $('.choose').click(function(e) {
      filepicker.pick({ mimetype: 'audio/*'}, 
                        {}, 
                      function(InkBlobs) { alert('done'); console.log(stringify(InkBlobs));
                      });
    });


    $('#searchbox').keyup(function() {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#catalog-list']);
    });

    $('#songInfoForm').on('click', '#id3Submit', function(event) {
      // set the data values on the corresponding div
      var correspondingDiv = '*[data-key="' + $('#songInfoModal').attr("data-key") + '"]';
      $(correspondingDiv + ' .status').text('Resubmit');
      $(correspondingDiv).attr("data-title", $('#title').val());
      $(correspondingDiv).attr("data-album", $('#album').val());
      $(correspondingDiv).attr("data-artist", $('#artist').val());
      markAsProcessing(correspondingDiv);

      // get matches
      var songInfo = ({ artist: $('#artist').val(), 
                          title: $('#title').val(),
                          album: $('#album').val(),
                            key: $('#songInfoModal').attr('data-key'),
                        filename: $('#songInfoModal').attr('data-filename')  });

      $('#songInfoForm').foundation('reveal','close');
      // check for echonest match again
      $.ajax({
            type: 'POST',
            dataType: 'json',
            url: '/upload/get_echonest_id',
            contentType: 'application/json',
            data: JSON.stringify(songInfo),
            success: function(result) {
              if (result.table.echonest_id) {  // if an echonest_id was found
                $.ajax({
                    type: "POST",
                    dataType: "json",
                    url: '/upload/process_song_by_echonest_id',
                    contentType: 'application/json',
                    data: JSON.stringify({ key: songInfo.key,
                                            echonest_id: result.table.echonest_id }),
                    success: function(result) {
                      $('#songInfoModal').foundation('reveal', 'close');
                      markAsAdded(correspondingDiv);
                    }
                });
              } else {
                
                $.ajax({
                      type: "POST",
                      dataType: "json",
                      url: '/upload/get_song_match_possibilities',
                      contentType: 'application/json',
                      data: JSON.stringify(songInfo),
                      
                      success: function(result) {
                        $('#songInfoModal').foundation('reveal', 'close');
                        $('#chooseMatch').foundation('reveal', 'open');
                        $('#chooseMatch .filenameDisplay').text(songInfo.filename);
                        $('#chooseMatch .titleDisplay').text(songInfo.title);
                        $('#chooseMatch .artistDisplay').text(songInfo.artist);
                        $('#chooseMatch').attr('data-key', songInfo.key);
                        $('#chooseMatch').attr('data_album', songInfo.album);
                        refreshSongMatchTable(result.table.songlist);
                      }
                });
              }
            }
      });
    });

    $('#chooseMatch').on('click', '#addSongByEchonestIdButton', function(event) {
      event.preventDefault();
      var songInfo = {};
      var selected = $("input[type='radio'][name='songSelect']:checked").val();
      if (selected === 'ECHONESTIDNOTFOUND') {
        songInfo.title = $('#chooseMatch').attr('data-title');
        songInfo.artist = $('#chooseMatch').attr('data-artist');
        songInfo.album = $('#chooseMatch').attr('data-album');
        songInfo.key = $('#chooseMatch').attr('data-key');
        $('#chooseMatch').foundation('reveal', 'close');

        // add the song without echonestId
        $.ajax({
            type: "POST",
            dataType: "json",
            url: '/upload/process_song_without_echonest_id',
            contentType: 'application/json',
            data: JSON.stringify(songInfo),
            success: function(result) {
              var correspondingDiv = '*[data-key="' + songInfo.key + '"]';
              if (result.table.error === 'song_already_exists') {
                markAsAlreadyUploaded(correspondingDiv);
              } else {
                markAsAdded(correspondingDiv);
              }
            }
        });

      // else add the song with it's echonestId
      } else {
        var key = $('#chooseMatch').attr('data-key');
        $('#chooseMatch').foundation('reveal','close');
        var correspondingDiv = '*[data-key="' + key + '"]';
        markAsProcessing(correspondingDiv);

        $.ajax({
            type: "POST",
            dataType: "json",
            url: '/upload/process_song_by_echonest_id',
            contentType: 'application/json',
            data: JSON.stringify({ key: key,
                                    echonest_id: selected }),
            success: function(result) {
              markAsAdded(correspondingDiv);
            }
        });
      } 
        songInfo.echonestId = selected;
    });

    var renderChooseSongTableRow = function(attrs) {
      var html = '<tr><td><input type="radio" name="songSelect" value="' + 
                  attrs.echonest_id + '" id="songSelect" /></td>' +
                  '<td>' + attrs.artist + '</td>' + 
                  '<td>' + attrs.title + '</td></tr>';
      return html;
    };

    var refreshSongMatchTable = function(songlist) {
      // clear modal first
      $('#chooseSongTable tbody').empty();

      // create the table
      for (var i=0; i<songlist.length; i++) {
        var html = renderChooseSongTableRow(songlist[i]);
        $('#chooseSongTable tbody').append(html);
      }
    };

    var markAsAlreadyUploaded = function(correspondingDiv) {
      $(correspondingDiv).addClass("success");
      $(correspondingDiv + ' .status').text('Already Uploaded');
      $(correspondingDiv).prepend('<a href="#" class="close">&times;</a>');
      $(correspondingDiv + ' .processing-icon').addClass('hide');
      $(correspondingDiv + ' .status').after('<button class="addToMyStationButton tiny button">Add to my Station</button>');
      $(correspondingDiv).addClass('four-item-li');
    };

    var markAsAdded = function(correspondingDiv) {
      $(correspondingDiv).addClass("success");
      $(correspondingDiv + ' .status').text('Song has been Added');
      $(correspondingDiv).prepend('<a href="#" class="close">&times;</a>');
      $(correspondingDiv + ' .processing-icon').addClass('hide');
      $(correspondingDiv + ' .status').removeClass('button');
    };

    var markAsProcessing = function(correspondingDiv) {
      $(correspondingDiv + ' .status').removeClass('button');
      $(correspondingDiv + ' .status').text('processing...');
      $(correspondingDiv + ' .processing-icon').removeClass('hide');
    };
  } //endif
})();
