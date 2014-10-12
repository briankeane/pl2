(function(){
  if ($('body.stations.dj_booth').length) {
    
    // load audioQueue
    for (var i=0;i<gon.audioQueue.length;i++) {
      gon.audioQueue[i].audio = new Audio(gon.audioQueue[i].key);
    }
    
    // set the next advance
    var msTillAdvanceSpin = (gon.audioQueue[1].airtime_in_ms - Date.now());
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);

    // seek the proper place in the first song and play it
    gon.audioQueue[0].audio.addEventListener('canplaythrough', function() {

      // set timer for next advance
      setTimeout(function() {

      });

      // if it hasn't already started
      if (!gon["musicStarted"]) {
        // set flag so it only executes once
        gon["musicStarted"] = true;

        // give it a few seconds to load or it'll be choppy
        var t = setTimeout(function() { 
          gon.audioQueue[0].audio.play();
          gon.audioQueue[0].audio.currentTime = (Date.now() - gon.audioQueue[0].airtime_in_ms)/1000;
        }, 5000);
          gon.audioQueue[0].audio.addEventListener('play', function() {

    setInterval(function() { updateProgressBar() }, 1000);
          });
      }
    });
    
    // set up the progress bar
    //gon.audioQueue[0].audio.addEventListener('timeupdate', function() { updateProgressBar(); });

    $('#searchbox').keyup(function(event) {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#all-songs-source-list']);
    });

    $('#recording').sortable({
                            dropOnEmpty: true,
                            connectWith: '#schedule-list',
                            
    });

    $('#all-songs-source-list').sortable({ 
      connectWith: '#schedule-list',
      helper: 'clone',
      widgets: ['zebra'],
      cancel: ".disabled",
      stop: function(event, ui) {
        $('#all-songs-source-list').sortable('cancel');
      },
      start: function(event, ui) {
        ui.item.type = 'song';
      }
    });

    $('#schedule-list').sortable({
      connectWith: '#all-songs-source-list',
      items: "li:not(.disabled)",
      start: function(event, ui) {
        ui.item.startPos = ui.item.index();
      },
      stop: function(event, ui) {
        $('#schedule-list .commercialBlock').removeClass('disabled');
        
        // return if order did not change
        if (ui.item.startPos == ui.item.index()) {return; }

        // create an array with just the spin current_ids
        var currentPositions = [];

        $('#schedule-list li').each(function(index, data) {
          if (!($(this).hasClass('commercialBlock'))) {
            currentPositions.push(parseInt($(this).attr('data-currentPosition')));
          }
        });

        var movePositionData = getMovePositions(currentPositions);

        // if they just moved around a commercial, cancel it
        if (!movePositionData.moved) {
          $('#schedule-list').sortable('cancel');
          $('#schedule-list .commercialBlock').addClass('disabled');
          //$('#schedule-list').disableSelection();
          return;
        }
        // disable list until request has come back
        $('#schedule-list').sortable('disable');
        // make ajax request to update database
        movePositionData._method = 'POST';
        $.ajax({
          type: 'POST',
          dataType: 'json',
          url: 'schedules/move_spin',
          contentType: 'application/json',
          data: JSON.stringify(movePositionData),
          success: function(result) {
            refreshScheduleList(result.table); 
            $('#schedule-list').sortable('enable');
          }
        });
      },
      receive: function(event, ui) {
        var insertSpinInfo = {};
        insertSpinInfo.songId = $(ui.item).attr('data-id');
        insertSpinInfo.lastCurrentPosition = $('#schedule-list').attr('data-lastCurrentPosition');

        // grab the insert position
        insertSpinInfo.addPosition = $('#schedule-list li').eq(ui.item.index() + 1).attr('data-currentPosition');
        
        // if there was a commercialBlock there, use the spin after instead
        if (!insertSpinInfo.addPosition) {
          insertSpinInfo.addPosition = $('#schedule-list li').eq(ui.item.index() + 2).attr('data-currentPosition');
        }

        // if it was a song
        if (ui.item.type === 'song') {
          // create the new html spin and add it
          var html = renderSpin({ estimated_airtime: '',
                                   current_position: insertSpinInfo.addPosition,
                                   title: $(ui.item).find('.songlist-title').text(),
                                   artist: $(ui.item).find('.songlist-artist').text() });
          $(ui.item).after(html);

          // then cancel so the original song item remains in the master list
          $('#all-songs-source-list').sortable('cancel');

          // disable list until results come back
          $('#schedule-list').sortable('disable');

          $.ajax({
            type: 'POST',
            dataType: 'json',
            url: 'schedules/insert_song',
            contentType: 'application/json',
            data: JSON.stringify(insertSpinInfo),
            success: function(result) {
              refreshScheduleList(result.table);
              // update new lastCurrentPosition on the DOM
              $('#schedule-list').attr('data-lastCurrentPosition', result.table.max_position);

              $('#schedule-list').sortable('enable');
            }
          });

        } else {  // otherwise if it was a commentary
          var html = renderCommentary({ estimated_airtime: '',
                                   current_position: insertSpinInfo.addPosition,
                                   sourceLink: ui.item.children()[0].src });
          
          // add the formatted commentary and delete the original item
          $(ui.item).after(html);

          insertSpinInfo.duration = ui.item.children()[0].duration * 1000 //converted to ms
          
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
          $('#schedule-list').sortable('disable');
          
          $.ajax({
            type:'POST',
            url:'schedules/process_commentary',
            data: fd,
            processData: false,
            contentType: false,
            success: function(result) {
              refreshScheduleList(result.table);

              // update new lastCurrentPosition on the DOM
              $('#schedule-list').attr('data-lastCurrentPosition', result.table.max_position);

              // reactivate schedule-list
              $('#schedule-list').sortable('enable');
            }
          }).done(function(data) {
            console.log(data);
          });
        }
          
      }  

    });

    $('#schedule-list').disableSelection();
    
    $(document).on('click', '#schedule-list li .close', function(event) {
      event.preventDefault();
      var currentPosition = parseInt($(this).parent().attr('data-currentPosition'));
      removeSpin(currentPosition);
    });


    // set up mute button
    $('.muteButton').click(function() {
      toggleStationMute();
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
    // * placements in the schedule-list          *
    // ********************************************
    var refreshScheduleList = function(result) {
      // change currentPositions data attr to reflect new positions
      var cpCounter = parseInt($('#schedule-list').attr('data-firstCurrentPosition'));
      $('#schedule-list li').each(function(index, data) {
        if (!$(this).hasClass('commercialBlock')) {
          $(this).attr('data-currentPosition', cpCounter);
          cpCounter ++;
        }
      });

      // delete all commercial Blocks between the max and min currentPositions
      var index = $('*[data-currentPosition="' + result.min_position +'"]').index();
      var maxIndex = $('*[data-currentPosition="' + result.max_position +'"]').index();

      // adjust for cases where full schedule is updated
      if (maxIndex === -1) {
        maxIndex = $('#schedule-list li').last().index();
      }

      while (index <= maxIndex) {
        if ($('#schedule-list li').eq(index).hasClass('commercialBlock')) {
          $('#schedule-list li').eq(index).remove();
        }
        index++;
      };

      // update times/commercial blocks for each item in new_program
      var newProgram = result.new_program;
      for(var i=0; i<newProgram.length; i++) {
        if (!newProgram[i].hasOwnProperty('commercials')) {
          var currentSpinLi = ('*[data-currentPosition="' + newProgram[i].current_position +'"]');
          $(currentSpinLi + ' .songlist-airtime').text(newProgram[i].estimated_airtime);
        } else {
          // if the last entry is a commercial, delete the following commercial so there are no duplicates
          if (i === newProgram.length - 1) {
            $(currentSpinLi).next().remove();
          }
          
          $(currentSpinLi).after("<li class='commercialBlock disabled'>" + 
                                  "<span class='songlist-title'>Commercial Block</span>" + 
                                  "<span class='songlist-airtime'>" +   newProgram[i].estimated_airtime + "</span></li>");
        }
      } //endFor
      
      //disable commercialBlock movement
      $('#schedule-list .commercialBlock').addClass('disabled');
      $('#schedule-list').sortable({
        items: "li:not(.disabled)"
      });
      $('#schedule-list').disableSelection();
    }

    // ********************************************
    // *               renderSpin                 *
    // *                                          *
    // *  -- takes a spinInfo object and returns  *
    // *  a string of html                        *
    // ********************************************
    var renderSpin = function(spinInfo) {
      
      if (spinInfo.hasOwnProperty('currentPosition')) {
        var currentPosition = spinInfo.currentPosition;
      } else {
        var currentPosition = '';
      }

      var html = '<li class="song ui-sortable-handle" data-currentPosition="' + 
                  currentPosition + '"><span class="songlist-title">' + spinInfo.title + 
                  '</span><span class="songlist-artist">' + spinInfo.artist + '</span>' +
                  '<span class="songlist-airtime">' + spinInfo.estimated_airtime + 
                  '</span><a href="#" class="close" title="delete">×</a></li>';
      return html;
    }
     // *******************************************
    // *               renderCommentary           *
    // *                                          *
    // *  -- takes a spinInfo object and returns  *
    // *  a string of html                        *
    // ********************************************
    var renderCommentary = function(spinInfo) {
      
      if (spinInfo.hasOwnProperty('currentPosition')) {
        var currentPosition = spinInfo.currentPosition;
      } else {
        var currentPosition = '';
      }

      var html = '<li class="commentary ui-sortable-handle" data-currentPosition="' + 
                  spinInfo.currentPosition + '"><span class="songlist-title">Commentary' + 
                  '</span><span class="songlist-artist"><audio controls src="' + spinInfo.sourceLink + '"></audio></span>' +
                  '<span class="songlist-airtime">' + spinInfo.estimated_airtime + '</span><a href="#" class="close">&times;</a></li>';
      return html;
    }


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
    }
  }

  // *********************************************
  // *           updateProgressBar               *
  // *                                           *
  // *  -- updates the per-song station progress *
  // *********************************************
  var updateProgressBar = function() {
    var elapsedTime = gon.audioQueue[0].audio.currentTime;
    var msRemaining = (gon.audioQueue[1].airtime_in_ms - Date.now());
    var percentComplete = elapsedTime/(elapsedTime + msRemaining/1000)*100;
    $('.progress .meter').css('width', percentComplete + '%');
    $('.nowPlayingTimes .elapsedTime').text(formatSongFromMS(Math.round(elapsedTime) * 1000));
    
    $('.nowPlayingTimes .timeRemaining').text('-' + formatSongFromMS(msRemaining));

    // if there's less than 10 secs left
    if (msRemaining <= 10000) {
      // set the color to red
      $('.nowPlayingTimes .timeRemaining').css('color', 'red');
    } else {
      $('.nowPlayingTimes .timeRemaining').css('color', 'black');
    }

  };

  var advanceSpin= function() { 
    // advance audioQueue
    gon.audioQueue.shift();

    // create callback for ajax request
    var updateQueue = function(result) {
      console.log(result);
      return result;
    }

    getSpinByCurrentPosition(gon.audioQueue[gon.audioQueue.length-1].currentPosition + 1, updateQueue);

    // play the new song
    gon.audioQueue[0].audio.play();
    var msTillAdvanceSpin = (gon.audioQueue[1].airtime_in_ms - Date.now());

    // clear the previous class
    $('#nowPlayingList .nowPlaying').removeClass('song');
    $('#nowPlayingList .nowPlaying').removeClass('commercialBlock');
    $('#nowPlayingList .nowPlaying').removeClass('commentary');
    
    // update the class and info
    if (gon.audioQueue[0].type === 'Song') {
      $('#nowPlayingList .nowPlaying').addClass('song');
      $('#nowPlayingList .nowPlaying .title b').text(gon.audioQueue[0].title);
      $('#nowPlayingList .nowPlaying .artist').text(gon.audioQueue[0].artist);
    } else if (gon.audioQueue[0].type === 'Commentary') {
      $('#nowPlayingList .nowPlaying').addClass('commentary');
      $('#nowPlayingList .nowPlaying .title b').text('Commentary');
      $('#nowPlayingList .nowPlaying .artist').text('');

    } else if (gon.audioQueue.type === 'CommercialBlock') {
      $('#nowPlayingList .nowPlaying').addClass('commercialBlock');
    }
    // set up next advance
    setTimeout(function() { advanceSpin(); }, msTillAdvanceSpin);
  };



  var getSpinByCurrentPosition = function(currentPosition, callback) {
    var getSpinInfo = {};
    getSpinInfo.last_current_position = parseInt($('#schedule-list').attr('data-lastCurrentPosition'));
    getSpinInfo.current_position = currentPosition;

    $.ajax({
          type: 'GET',
          dataType: 'json',
          url: 'schedules/get_spin_by_current_position',
          contentType: 'application/json',
          data: JSON.stringify(getSpinInfo),
          success: callback
        });
  }

  var toggleStationMute = function() {
    // change image
    $('.muteButton').toggleClass('muted');

    for (var i=0; i<gon.audioQueue.length; i++) {
      gon.audioQueue[i].audio.muted = !gon.audioQueue[i].audio.muted;
    }
  }

  var removeSpin = function(currentPosition) {
    var removeSpinInfo = {};
    removeSpinInfo.last_current_position = parseInt($('#schedule-list').attr('data-lastCurrentPosition'));
    removeSpinInfo.current_position = currentPosition;

    $.ajax({
          type: 'DELETE',
          dataType: 'json',
          url: 'schedules/remove_spin',
          contentType: 'application/json',
          data: JSON.stringify(removeSpinInfo),
          success: function(result) {
            $('*[data-currentPosition="' + result.table.removed_spin.current_position +'"]').remove();
            result.max_index = -1;
            refreshScheduleList(result.table);
          }
    });
  

  }


})();