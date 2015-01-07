(function(){
  if ($('body.stations.dj_booth').length) {
    
    // ********************************************
    // *           joyRide Tour                   *
    // ********************************************
    $(document).foundation({
      'joyride': 
        { 'cookie_monster': !$.cookie('joyride') ? false : true,
          post_ride_callback : function () {
            !$.cookie('joyride') ? $.cookie('joyride', 'ridden') : null;
          }   
        }
    }).foundation('joyride', 'start');
    
    $('#tour').foundation({
        joyride: {
          cookie_monster: true,
          cookie_name: 'joyride',
          cookie_domain: true,
          cookie_expires: 365,
          modal: false
        }
      });

    // set up progressbar updating
    $(document).on('playerStarted', function() {
       setInterval(function() { updateProgressBar(); }, 500);
    });

    $(document).on('spinAdvanced', function() {
      updateSpinDisplay();
    });

    $(document).on('recordingStarted', function() {
      var muteStateBeforeRecording = gon.player.muted;
      if (!gon.player.muted) {
        toggleStationMute();
      }
      $(document).on('recordingStopped', function() {
        if (!muteStateBeforeRecording) {
          toggleStationMute();
        }
      });
    });

    // create and start player
    console.log(navigator.sayswho.split(" ")[0]);
    if (navigator.sayswho.split(" ")[0] === 'Chrome') {
      gon.player = new webAudioStationPlayer(gon);
    } else {
      gon.player = new StationPlayer(gon);
    }
    gon.player.startPlayer();

    $('#searchbox').keyup(function(event) {
      updateCatalogList();
    });

    $('#onlyMySongs').on('click', function() {
      updateCatalogList();
    });

    $('#recording').sortable({
                            dropOnEmpty: true,
                            connectWith: '#station-list'              
    });

    $('#catalog-list').sortable({ 
      connectWith: '#station-list',
      helper: 'clone',
      widgets: ['zebra'],
      cancel: ".disabled",
      stop: function(event, ui) {
        $('#catalog-list').sortable('cancel');
      },
      start: function(event, ui) {
        ui.item.type = 'song';
      }
    });

    // disable first two lis
    $('#station-list li:nth-child(1), li:nth-child(2)').addClass('disabled');
    $('#station-list li:nth-child(1), li:nth-child(2)').removeClass('ui-sortable-handle');
    $('#station-list li:nth-child(1), li:nth-child(2)').find('.close').remove();

    $('#station-list').sortable({
      connectWith: '#catalog-list',
      items: "li:not(.disabled)",
      start: function(event, ui) {
        ui.item.startPos = ui.item.index();
      },
      stop: function(event, ui) {
        $('#station-list .commercialBlock').removeClass('disabled');
        
        // return if order did not change
        if (ui.item.startPos == ui.item.index()) {
          $('#station-list').sortable('enable');
          return; }

        // create an array with just the spin current_ids
        var currentPositions = [];

        $('#station-list li').each(function(index, data) {
          if (!($(this).hasClass('commercialBlock'))) {
            currentPositions.push(parseInt($(this).attr('data-currentPosition')));
          }
        });

        var movePositionData = getMovePositions(currentPositions);

        // if they just moved around a commercial, cancel it
        if (!movePositionData.moved) {
          $('#station-list').sortable('cancel');
          $('#station-list .commercialBlock').addClass('disabled');
          //$('#station-list').disableSelection();
          return;
        }
        // disable list until request has come back
        $('#station-list').sortable('disable');
        // make ajax request to update database
        movePositionData._method = 'POST';
        $.ajax({
          type: 'POST',
          dataType: 'json',
          url: 'stations/move_spin',
          contentType: 'application/json',
          data: JSON.stringify(movePositionData),
          success: function(result) {
            refreshScheduleList(result.table); 
            $('#station-list').sortable('enable');
          }
        });
      },
      receive: function(event, ui) {
        var insertSpinInfo = {};
        insertSpinInfo.songId = $(ui.item).attr('data-id');
        insertSpinInfo.lastCurrentPosition = $('#station-list').attr('data-lastCurrentPosition');

        // grab the insert position
        insertSpinInfo.addPosition = $('#station-list li').eq(ui.item.index() + 1).attr('data-currentPosition');
        
        // if there was a commercialBlock there, use the spin after instead
        if (!insertSpinInfo.addPosition) {
          insertSpinInfo.addPosition = $('#station-list li').eq(ui.item.index() + 2).attr('data-currentPosition');
        }

        // if it was a song
        if (ui.item.type === 'song') {
          // create the new html spin and add it
          var html = renderSpin({ airtime: '',
                                   current_position: insertSpinInfo.addPosition,
                                   title: $(ui.item).find('.songlist-title').text(),
                                   artist: $(ui.item).find('.songlist-artist').text() });
          $(ui.item).after(html);

          // then cancel so the original song item remains in the master list
          $('#catalog-list').sortable('cancel');

          // disable list until results come back
          $('#station-list').sortable('disable');

          $.ajax({
            type: 'POST',
            dataType: 'json',
            url: 'stations/insert_song',
            contentType: 'application/json',
            data: JSON.stringify(insertSpinInfo),
            success: function(result) {
              refreshScheduleList(result.table);
              // update new lastCurrentPosition on the DOM
              $('#station-list').attr('data-lastCurrentPosition', result.table.max_position);
              $('#station-list').sortable('enable');
            }
          });

        } else {  // otherwise if it was a commentary
          var html = renderCommentary({ airtime: '',
                                   current_position: insertSpinInfo.addPosition,
                                   sourceLink: ui.item.children()[0].src });
          
          // add the formatted commentary and delete the original item
          $(ui.item).after(html);

          insertSpinInfo.duration = ui.item.children()[0].duration * 1000; //converted to ms
          
          // return original li to old list and clear it
          $('#recording').sortable('cancel');
          $('#recording .commentary audio').remove();
          $('#recording .commentary a').remove();

          // re-enable recording
          $('#startRecording').removeAttr('disabled');


          var fd = new FormData();
          fd.append('fname','comment.wav');
          fd.append('data', window.currentBlob);
          fd.append('addPosition', insertSpinInfo.addPosition);
          fd.append('lastCurrentPosition', insertSpinInfo.lastCurrentPosition);
          fd.append('duration', insertSpinInfo.duration);
          
          // disable the list until the results come back
          $('#station-list').sortable('disable');
          
          $.ajax({
            type:'POST',
            url:'stations/process_commentary',
            data: fd,
            processData: false,
            contentType: false,
            success: function(result) {
              refreshScheduleList(result.table);

              // update new lastCurrentPosition on the DOM
              $('#station-list').attr('data-lastCurrentPosition', result.table.max_position);

              // reactivate station-list
              $('#station-list').sortable({
                items: "li:not(.disabled)"
              });
            }
          }).done(function(data) {
            console.log(data);
          });
        }
          
      }  

    });

    $('#station-list').disableSelection();
    
    $(document).on('click', '#station-list li .close', function() { 
      removeSpin();
    });

    // set up mute button
    $('.muteButton').click(function() {
      toggleStationMute();
    });


    // refresh page on wake from sleep
    onWakeFromSleep(function() {
      // location = location;          // disabled
    });

    // ********************************************
    // *       refreshScheduleList                *
    // *                                          *
    // *  -- takes an object with:                *
    // *                  max_position            *
    // *                  min_position            *
    // *                  new_program (array)     *
    // ********************************************
    // * updates the times and commercial         *
    // * placements in the station-list          *
    // ********************************************
    var refreshScheduleList = function(result) {
      // change currentPositions data attr to reflect new positions
      var cpCounter = parseInt($('#station-list').attr('data-firstCurrentPosition'));
      $('#station-list li').each(function(index, data) {
        if (!$(this).hasClass('commercialBlock')) {
          $(this).attr('data-currentPosition', cpCounter);
          cpCounter ++;
        }
      });

      // delete all commercial Blocks between the max and min currentPositions
      var index = $('*[data-currentPosition="' + result.min_position +'"]').index();
      var maxIndex = $('*[data-currentPosition="' + result.max_position +'"]').index();

      // adjust for cases where full station is updated
      if (maxIndex === -1) {
        maxIndex = $('#station-list li').last().index();
      }

      while (index <= maxIndex) {
        if ($('#station-list li').eq(index).hasClass('commercialBlock')) {
          $('#station-list li').eq(index).remove();
        }
        index++;
      }

      // update times/commercial blocks for each item in new_program
      var newProgram = result.new_program;
      for(var i=0; i<newProgram.length; i++) {
        if (!newProgram[i].hasOwnProperty('commercials')) {
          var currentSpinLi = ('*[data-currentPosition="' + newProgram[i].current_position +'"]');
          $(currentSpinLi + ' .songlist-airtime').text(newProgram[i].airtimeForDisplay);
        } else {
          // if the last entry is a commercial, delete the following commercial so there are no duplicates
          if (i === newProgram.length - 1) {
            $(currentSpinLi).next().remove();
          }
          
          $(currentSpinLi).after("<li class='commercialBlock disabled'>" + 
                                  "<span class='songlist-title'>Commercial Block</span>" + 
                                  "<span class='songlist-airtime'>" +   newProgram[i].airtimeForDisplay + "</span></li>");
        }
      } //endFor
      
      //disable commercialBlock movement
      $('#station-list .commercialBlock').addClass('disabled');
      $('#station-list').sortable({
        items: "li:not(.disabled)"
      });
      $('#station-list').disableSelection();
    };

    // ********************************************
    // *               renderSpin                 *
    // *                                          *
    // *  -- takes a spinInfo object and returns  *
    // *  a string of html                        *
    // ********************************************
    var renderSpin = function(spinInfo) {
      
      var currentPosition;
      if (spinInfo.hasOwnProperty('currentPosition')) {
        currentPosition = spinInfo.currentPosition;
      } else {
        currentPosition = '';
      }

      var html = '<li class="song ui-sortable-handle" data-currentPosition="' + 
                  currentPosition + '"><span class="songlist-title">' + spinInfo.title + 
                  '</span><span class="songlist-artist">' + spinInfo.artist + '</span>' +
                  '<span class="songlist-airtime">' + spinInfo.airtime + 
                  '</span><a href="#" class="close" title="delete">×</a></li>';
      return html;
    };
    
    // *******************************************
    // *               renderCommentary           *
    // *                                          *
    // *  -- takes a spinInfo object and returns  *
    // *  a string of html                        *
    // ********************************************
    var renderCommentary = function(spinInfo) {
      
      var currentPosition;
      if (spinInfo.hasOwnProperty('currentPosition')) {
        currentPosition = spinInfo.currentPosition;
      } else {
        currentPosition = '';
      }

      var html = '<li class="commentary ui-sortable-handle" data-currentPosition="' + 
                  spinInfo.currentPosition + '"><span class="songlist-title">Commentary' + 
                  '</span><span class="songlist-artist"><audio controls src="' + spinInfo.sourceLink + '"></audio></span>' +
                  '<span class="songlist-airtime">' + spinInfo.airtime + '</span><a href="#" class="close">&times;</a></li>';
      return html;
    };

    // ********************************************
    // *          renderCommercialBlock           *
    // *                                          *
    // *  -- takes a spinInfo object and returns  *
    // *  a string of html                        *
    // ********************************************
    var renderCommercialBlock = function(spinInfo) {
      
      if (spinInfo.hasOwnProperty('currentPosition')) {
        var currentPosition = spinInfo.currentPosition;
      } else {
        var currentPosition = '';
      }

      var html = '<li class="commercialBlock ui-sortable-handle" data-currentPosition="' + 
                  spinInfo.currentPosition + '"><span class="songlist-title">Commercial Block' + 
                  '</span><span class="songlist-artist"></span>' +
                  '<span class="songlist-airtime">' + spinInfo.airtimeForDisplay + '</span></li>';
      return html;
    };

    // ********************************************
    // *             updateCatalogList            *
    // *                                          *
    // *  -- updates the catalog list             *
    // ********************************************
    var updateCatalogList = function() {
      var searchText = $('#searchbox').val();
        
      if ($('#onlyMySongs').is(':checked')) {
        $('#catalog-list').empty();

        // if searchText is empty, set flag
        var emptyFlag = false;
        if(searchText.trim() === '') {
          emptyFlag = true;
          var searchTextArray = [];
        } else {
          emptyFlag = false;
          searchTextArray = searchText.trim().split(' ');
        }

        gon.songsInRotation.forEach(function(song) {
          var includeSong = true;
          if (!emptyFlag) {
            includeSong = true;
            searchTextArray.forEach(function(word) {
              // if word is not included in either song or artist
              if (!(new RegExp(word, "i")).test(song.artist + ' ' + song.title)) {
                includeSong = false;
              }
            });
          }

          if (includeSong) {
            $('#catalog-list').append(renderCatalogLi(song));     
          }
        });
      } else {
        searchSonglist(searchText);
      }
    };


    // ********************************************
    // *           getMovePositions               *
    // *                                          *
    // *  -- takes an array of integers and       *
    // *  determines which obj is out of sequence *
    // * RETURNS: object { newPosition: INT,      *
    // *                   oldPosition: INT,      *
    // *                   moved: BOOLEAN }       *
    // ********************************************
    var getMovePositions = function(spinsArray) {
      // iterate through the array to find the out of place number
      var currentPositionCounter = spinsArray[0]-1;
      var oldPositionCounter = null;
      var newPositionCounter = null;
      var movePositionData = {};

      for (var i in spinsArray) {
        currentPositionCounter++;
        if (spinsArray[i] != currentPositionCounter) {
          if (!(movePositionData.hasOwnProperty('oldPosition'))) {  // if we haven't come across anything yet
            if (spinsArray[i] == currentPositionCounter + 1) { // if there's one missing
              movePositionData.oldPosition = currentPositionCounter;
              currentPositionCounter++;
            } else {  // otherwise store both positions and break
              movePositionData.newPosition = currentPositionCounter;
              movePositionData.oldPosition = spinsArray[i];
              break;
            }
          } else {  // (if we've already stored oldPosition and are just looking for newPosition)
            movePositionData.newPosition = currentPositionCounter - 1;
            break;
          }
        }
      }

      // mark whether or not it moved
      if (!movePositionData.newPosition) {
        movePositionData.moved = false;
      } else  {
        movePositionData.moved = true;
      }
      return movePositionData;
    };
  }

  // *********************************************
  // *           updateProgressBar               *
  // *                                           *
  // *  -- updates the per-song station progress *
  // *********************************************
  var updateProgressBar = function() {
    var elapsedTime = Date.now() - gon.player.audioQueue[0].airtime_in_ms;
    var msRemaining = (gon.player.audioQueue[1].airtime_in_ms - Date.now());
    var percentComplete = elapsedTime/(elapsedTime + msRemaining)*100;
    $('.progress .meter').css('width', percentComplete + '%');
    $('.nowPlayingTimes .elapsedTime').text(formatSongFromMS(Math.round(elapsedTime)));
    
    $('.nowPlayingTimes .timeRemaining').text('-' + formatSongFromMS(msRemaining));

    // show the muteButton if it's invisible
    if($('.muteButton').css('display') === 'none') {
      $('.muteButton').show();
    }

    // if there's less than 10 secs left
    if (msRemaining <= 10000) {
      // set the color to red
      $('.nowPlayingTimes .timeRemaining').css('color', 'red');
    } else {
      $('.nowPlayingTimes .timeRemaining').css('color', 'black');
    }
  };

  var updateSpinDisplay = function() { 
    // clear the previous class
    $('#nowPlayingList .nowPlaying').removeClass('song');
    $('#nowPlayingList .nowPlaying').removeClass('commercialBlock');
    $('#nowPlayingList .nowPlaying').removeClass('commentary');
    
    // update the class and info
    if (gon.audioQueue[0].type === 'Song') {
      $('#nowPlayingList .nowPlaying').addClass('song');
      $('#nowPlayingList .nowPlaying .title').text(gon.audioQueue[0].title);
      $('#nowPlayingList .nowPlaying .artist').text(gon.audioQueue[0].artist);
    } else if (gon.audioQueue[0].type === 'Commentary') {
      $('#nowPlayingList .nowPlaying').addClass('commentary');
      $('#nowPlayingList .nowPlaying .title').text('Commentary');
      $('#nowPlayingList .nowPlaying .artist').text('');
    } else {
      $('#nowPlayingList .nowPlaying').addClass('commercialBlock');
      $('#nowPlayingList .nowPlaying .title').text('Commercial Block');
      $('#nowPlayingList .nowPlaying .artist').text('');
    }

    // if the station is live, advance #station-list
    if (parseInt($('#station-list li').attr('data-currentPosition')) === gon.audioQueue[0].currentPosition)  {
      $('#station-list li').first().remove();

      // disable first two elements
      $('#station-list li:nth-child(1), #station-list li:nth-child(2)').addClass('disabled');
      $('#station-list li:nth-child(1), #station-list li:nth-child(2)').removeClass('ui-sortable-handle');
      $('#station-list li:nth-child(1), #station-list li:nth-child(2)').find('.close').remove();
      $('#station-list').sortable({
        items: "li:not(.disabled)"
      });
      appendNextSpin();
    }
  };

  var toggleStationMute = function() {
    // change image
    $('.muteButton').toggleClass('muted');
    if ($('.muteButton').hasClass('muted')) {
      gon.player.mute();
    } else {
      gon.player.unMute();
    }
  };

  var removeSpin = function() {
    event.preventDefault();

    // if the list is deactivated, do nothing
    if ($('#station-list').hasClass('ui-sortable-disabled')) {
      return;
    }

    var currentPosition = parseInt($(event.target).parent().attr('data-currentposition'));
    var removeSpinInfo = {};
    removeSpinInfo.last_current_position = parseInt($('#station-list').attr('data-lastCurrentPosition'));
    removeSpinInfo.current_position = currentPosition;
    
    //remove airtime and replace with processing icon
    var spinLiSelector = '*[data-currentPosition="' + currentPosition +'"]';
    $(spinLiSelector + ' .songlist-airtime').remove();
    $(spinLiSelector + ' .close').remove();
    $(spinLiSelector).append('<img src="/images/processing_icon.gif" class="processing-icon" />');

    // disable list until results come back
    $('#station-list').sortable('disable');

    $.ajax({
          type: 'DELETE',
          dataType: 'json',
          url: 'stations/remove_spin',
          contentType: 'application/json',
          data: JSON.stringify(removeSpinInfo),
          success: function(result) {
            $('*[data-currentPosition="' + result.table.removed_spin.current_position +'"]').remove();

            // adjust lastCurrentPosition
            var oldLastCurrentPosition = parseInt($('#station-list').attr('data-lastCurrentPosition'));
            $('#station-list').attr('data-lastCurrentPosition', oldLastCurrentPosition - 1);

            refreshScheduleList(result.table);
            $('#station-list').sortable({
              items: "li:not(.disabled)"
            });
            appendNextSpin();
          }
    });
  };

  var hideOutsideSongs = function() {
    $('#catalog-list li').each( function(index) {
      if ($(this).attr('data-isOnStation') != 'true') {
        $(this).hide();
      }
    });
  };


  var appendNextSpin = function() {
    var nextCurrentPosition = parseInt($('#station-list').attr('data-lastCurrentPosition')) + 1;
    var callback = function(result) {
      var html = renderSpin({ airtime: result.airtimeForDisplay,
                                 current_position: result.current_position,
                                 title: result.audio_block.title,
                                 artist: result.audio_block.artist });
      $('#station-list').append(html); 

      // increment lastCurrentPosition
      var oldLastCurrentPosition = parseInt($('#station-list').attr('data-lastCurrentPosition'));
      $('#station-list').attr('data-lastCurrentPosition', oldLastCurrentPosition + 1);

      if (result["commercials_follow?"] === true) {
        var html = renderCommercialBlock({ airtimeForDisplay: formatAirtimeFromMS(result.airtime_in_ms + result.audio_block.duration) });
        $('#station-list').append(html); 
      }
    };

    // build spinInfo object for getSpinByCurrentPosition
    var spinInfo = {};
    spinInfo.lastCurrentPosition = parseInt($('#station-list').attr('data-lastCurrentPosition'));
    spinInfo.currentPosition = nextCurrentPosition;
    spinInfo.stationId = gon.stationId;
    getSpinByCurrentPosition(spinInfo, callback);

  };

})();