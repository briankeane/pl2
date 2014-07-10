(function(){
  // (controller, action)
  if ($('body.station.dj_booth').length) {


    // initializations
    $(".progress-bar").attr("aria-valuenow", +new Date() - +currentSpin["played_at"]);
    $(".progress-bar").attr("aria-valuemax", currentSpin["audio_block"]["duration"]);
    $(".progress-bar").css("width", (((+new Date() - +currentSpin["played_at"])/currentSpin["audio_block"]["duration"]) * 100) + "%");
    $("#options-tabs").tabs({ active: 1 });
    $('#songlist').sortable({
        start: function(event, ui) {
          ui.item.startPos = ui.item.index();
        },
        stop: function(event, ui) {

          // return if order did not change
          if (ui.item.startPos === ui.item.index()) { return; }

          // create an array with the just the spin current_ids
          currentPositions = [];

          $('#songlist li').each( function(index, data) {
            if ($(this).hasClass('song')) {
              currentPositions.push(parseInt($(this).attr("data-id")));
            }
          });

          var movePositionData = getMovePositions(currentPositions);

          // make ajax request to update database
          movePositionData._method = 'POST';
          $.ajax({
              type: "POST",
              dataType: "json",
              url: 'station/update_order',
              contentType: 'application/json',
              data: JSON.stringify(movePositionData)
          });


          // update list
          currentPositionCounter = Math.min.apply(Math, currentPositions);
          $('#songlist li').each( function(index, data) {
            if ($(this).hasClass('song')) {
             $(this).attr("data-id", currentPositionCounter.toString());
            }
            currentPositionCounter++;
          });

        }
      });

    $('#recording').sortable({
              connectWith: "#songlist",
              remove: function(event, ui) {
                $('#recording').append('<li class="commentary" opacity="0.3"></li>');
                $('#startRecording').removeAttr('disabled');
              }

    }).disableSelection();



    // ********************************************
    // *           updateCurrentSpins             *
    // *                                          *
    // *  -- changes the 'now-playing' song when  *
    // *         the current Spin ends            *
    // ********************************************
    var updateCurrentSpins = function() {
      currentSpin = playlist.shift();
      currentSpin["played_at"] = new Date();
      $('#songlist li').first().remove();
      $('#now_playing .title').text(currentSpin["audio_block"]["title"]);
      $('#now_playing .artist').text(currentSpin["audio_block"]["artist"]);
      $(".progress-bar").attr("aria-valuenow", "0");
      $(".progress-bar").attr("aria-valuemax", currentSpin["audio_block"]["duration"]);
      $(".progress-bar").css("aria-valuenow", "0");
    }



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

    // updates all timers and progress-bars
    var updateTimers = function() {
      var msElapsed = +new Date() - +currentSpin["played_at"];
      $('#elapsed_time').text(formatSongFromMS(msElapsed));
      $('#time_remaining').text(formatSongFromMS(currentSpin["audio_block"]["duration"] - msElapsed));
      if (msElapsed >= currentSpin["audio_block"]["duration"]) {
        updateCurrentSpins();
      }
      $('.progress-bar').attr("aria-valuenow", msElapsed);
      $('.progress-bar').css("width", (((+new Date() - +currentSpin["played_at"])/currentSpin["audio_block"]["duration"]) * 100) + "%");
    }




  // update all clocks and timers
  setInterval(function () { updateTimers() }, 200); };




})();