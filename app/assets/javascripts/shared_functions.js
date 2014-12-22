$(document).ready(function() {
  // addToMyStationButton -- on dj_booth and stations#show
  $(document).on('click', '.addToMyStationButton', function() {
    if (!$(this).hasClass('disabled')) {
      var songId = parseInt($(this).attr('data-songId'));
      createSpinPerWeekListItem({ id: songId,
                    spinFrequency: 'Medium' });
      $(this).addClass('disabled');
      $(this).text('Song Added');
    }
  });

  $(document).on('click', '.addToMyPresets', function() {
    if ($(this).hasClass('add')) {
      $(this).removeClass('add');
      $(this).addClass('remove');
      $(this).text('Remove From My Presets');
      createPreset($(this).attr('data-stationId'));
    } else {
      $(this).removeClass('remove');
      $(this).addClass('add');
      $(this).text('Add Station To My Presets');
      deletePreset($(this).attr('data-stationId'));
    }
  });

  var createPreset = function(station_id) {
    $.ajax({
          type: 'POST',
          dataType: 'json',
          url: '/users/create_preset',
          contentType: 'application/json',
          data: JSON.stringify({ station_id: station_id }),
          success: function(result) {
            console.log(result);
          }
    });
  };

  var deletePreset = function(station_id) {
    $.ajax({
          type: 'DELETE',
          dataType: 'json',
          url: '/users/delete_preset',
          contentType: 'application/json',
          data: JSON.stringify({ station_id: station_id }),
          success: function(result) {
            console.log(result);
          }
    });
  };
});