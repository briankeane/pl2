(function(){
  if ($('body.stations.dj_booth').length) {
    
    $('#searchbox').keyup(function() {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#all-songs-source-list']);
    });

    $('#recording').sortable({
                            connectWith: '#schedule-list',
                            
    });

    $('#all-songs-source-list').sortable({ 
      connectWith: '#schedule-list',
      helper: 'clone',
      widgets: ['zebra'],
      cancel: ".disabled",
      stop: function(event, ui) {
        $('#all-songs-source-list').sortable('cancel');
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
          if ($(this).hasClass('song')) {
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
        var insertSongInfo = {};
        insertSongInfo.songId = $(ui.item).attr('data-id');
        insertSongInfo.lastCurrentPosition = $('#schedule-list').attr('data-lastCurrentPosition');

        // grab the insert position
        insertSongInfo.addPosition = $('#schedule-list li').eq(ui.item.index() + 1).attr('data-currentPosition');
        
        // if there was a commercialBlock there, use the spin after instead
        if (!insertSongInfo.addPosition) {
          insertSongInfo.addPosition = $('#schedule-list li').eq(ui.item.index() + 2).attr('data-currentPosition');
        }

        // if it was a song
        if (ui.item.attr('id') === 'all-songs-source-list') {
          // create the new html spin and add it
          var html = renderSpin({ estimated_airtime: '',
                                   current_position: insertSongInfo.addPosition,
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
            data: JSON.stringify(insertSongInfo),
            success: function(result) {
              refreshScheduleList(result.table);
              // update new lastCurrentPosition on the DOM
              $('#schedule-list').attr('data-lastCurrentPosition', result.table.max_position);

              $('#schedule-list').sortable('enable');
            }
          });
        } else {  // otherwise if it was a commentary
          console.log('a commentary was dropped');
          $('#recording').sortable('cancel');
        }
          
      }  

    });

    $('#schedule-list').disableSelection();
    
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
      var index = $('*[data-currentPosition="' + result.min_position +'"').index();
      var maxIndex = $('*[data-currentPosition="' + result.max_position +'"').index();

      // adjust for cases where full schedule is updated
      if (!maxIndex === -1) {
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
                                  "<span class-'songlist-title'>Commercial Block</span>" + 
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
                  '<span class="songlist-airtime">' + spinInfo.estimated_airtime + '</span></li>';
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

})();