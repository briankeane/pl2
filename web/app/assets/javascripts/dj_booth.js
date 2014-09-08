(function(){
  if ($('body.stations.dj_booth').length) {
    

    $('#schedule-list').sortable({
      start: function(event, ui) {
        ui.item.startPos = ui.item.index();
      },
      stop: function(event, ui) {

        // return if order did not change
        if (ui.item.startPos == ui.item.index()) {return; }

        // create an array with just the spin current_ids
        var currentPositions = [];

        $('#schedule-list li').each(function(index, data) {
          if ($(this).hasClass('song')) {
            currentPositions.push(parseInt($(this).attr('data-currentPosition')));
          }
        });

        $('#schedule-list li').each(function(index, data) {
          if ($(this).hasClass('commercialBlock')) {
            $(this).remove();
          }
        });
        
        var movePositionData = getMovePositions(currentPositions);


        // make ajax request to update database
        movePositionData._method = 'POST';
        $.ajax({
          type: 'POST',
          dataType: 'json',
          url: 'schedule/update_order',
          contentType: 'application/json',
          data: JSON.stringify(movePositionData),
          success: function(result) {
            console.log(result);
          }
        });
      }

    });

  }

})();