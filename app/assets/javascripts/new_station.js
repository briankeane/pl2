(function(){

  $(document).foundation({
    abide: {
      live_validate: true,
      focus_on_invalid: true,
      error_labels: true,
      patterns: {
        zipcode: /^\b\d{5}(-\d{4})?\b$/
      }
    }
  });

  // Get the User & Station Info if it's not yet complete
  if ($('#getUserInfoModal').data('userinfocomplete') === false) {
    $('#getUserInfoModal').foundation('reveal', 'open');
  } else {
    if ($('#getStationInfoModal').data('stationinfocomplete') === false) {
      $('#getStationInfoModal').foundation('reveal', 'open');
    }
  }
  
  $('#manualStationCreate').click( function () {
    $('#getArtists').trigger('createStation', 'manual');
  });

  $('#automaticStationCreate').click( function () {
    $('#getArtists').trigger('createStation', 'automatic');
  });

  $('#getArtists').on('createStation', function(event, createType) {
    $('#getArtists').addClass('hide');
    $('#creating').removeClass('hide');
    var input = $('<input>')
      .attr('type', 'hidden')
      .attr('name', 'createType').val(createType);
    $('#getArtists').append($(input));
    $('#getArtists').submit();
  });
 
  $('#userInfo').on('submit valid invalid', function(e) {
    e.stopPropagation();
    e.preventDefault();
    if (e.type === 'valid') {
      var birth_year = $('#date_year').val();
      var zipcode = $('#zipcode').val();
      var gender;
      if ($('#gender').val() === 'male') {
        gender = 'male';
      } else {
        gender = 'female';
      }
      
      var userInfo = {
        birth_year: birth_year,
        zipcode: zipcode,
        gender: gender,
        _method: 'post'
      };

      $.ajax({
        type: "POST",
        dataType: "json",
        url:'/users/update',
        contentType: 'application/json',
        data: JSON.stringify(userInfo),
        success: function(obj) {
          console.log(obj);
          $('#getUserInfoModal').foundation('reveal', 'close');
          $('#getStationInfoModal').foundation('reveal', 'open');

        }
      });
    } 
  });




  $('#create').on('click', function() {
    if ($('#heavy li').length < 13) {
      alert('Please add ' + ((13 - $('#heavy li').length)).toString() + ' songs to the heavy bin.');
    } else if ($('#medium li').length < 13) {
      alert('Please add ' + ((29 - $('#medium li').length)).toString() + ' songs to the medium bin.');
    } else if ($('#light li').length < 5) {
      alert('Please add ' + ((13 - $('#light li').length)).toString() + ' songs to the light bin.');
    } else {

      var heavyElements = $('#heavy li');
      var mediumElements = $('#heavy li');
      var lightElements = $('#heavy li');
      var heavyIds = [];
      var mediumIds = [];
      var lightIds = [];

      for (var i in heavyElements) {
        heavyIds.push(heavyElements.eq(i).attr('data-id'));
      }
      for (var i in mediumElements) {
        mediumIds.push(mediumElements.eq(i).attr('data-id'));
      }
      for (var i in lightElements) {
        lightIds.push(lightElements.eq(i).attr('data-id'));
      }

      var createStationInfo = {
        heavy: heavyIds,
        medium: mediumIds,
        light: lightIds
      };



      $.ajax({
        type: "POST",
        dataType: "json",
        url: '/station/create',
        contentType: 'application/json',
        data: JSON.stringify(createStationInfo),
        success: function(obj) {
          window.location = '/dj_booth';
        },
        error : function(error) {
          console.log(error);
        }
      });

    } //endif
  });  //end create event

})();