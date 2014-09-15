(function(){
  if ($('body.stations.dj_booth').length) {
    

    $('#schedule-list').sortable({
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

        // make ajax request to update database
        movePositionData._method = 'POST';
        $.ajax({
          type: 'POST',
          dataType: 'json',
          url: 'schedules/move_spin',
          contentType: 'application/json',
          data: JSON.stringify(movePositionData),
          success: function(result) {
            console.log(result);


            // change currentPositions data attr to reflect new positions
            var cpCounter = parseInt($('#schedule-list').attr('data-firstCurrentPosition'));
            $('#schedule-list li').each(function(index, data) {
              if (!$(this).hasClass('commercialBlock')) {
                $(this).attr('data-currentPosition', cpCounter);
                cpCounter ++;
              }
            });
            
            // delete all commercial Blocks between the max and min currentPositions
            var index = $('*[data-currentPosition="' + result.table.min_position +'"').index();
            var maxIndex = $('*[data-currentPosition="' + result.table.max_position +'"').index();

            while (index <= maxIndex) {
              if ($('#schedule-list li').eq(index).hasClass('commercialBlock')) {
                $('#schedule-list li').eq(index).remove();
              }
              index++;
            };

            // for every result
            var newProgram = result.table.new_program;
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
            
          } //end success

          
            
        });
      }

    });

    $('#schedule-list').disableSelection();
    
    // ********************************************
    // *       deleteCommercialBlocks             *
    // *                                          *
    // *  -- takes two currentPositions and       *
    // *     deletes all commercialBlock li       *
    // *     between them in the schedule list    *
    // ********************************************
    


    // ********************************************
    // *           getMovePositions               *
    // *                                          *
    // *  -- takes an array of integers and       *
    // *  determines which obj is out of sequence *
    // * RETURNS: object { newPosition: INT,      *
    // *                   oldPosition: INT }     *
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
      return movePositionData;
    }
  }

})();