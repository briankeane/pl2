(function() {
  if ($('body.stations').length) {
    
    $('#searchbox').keyup(function() {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#catalog-list']);
    });
    
    $('#catalog-list').sortable({ connectWith: '#spinsPerWeekList',
                                helper: 'clone',
                                widgets: ['zebra'],
                                cancel: ".disabled",
                                stop: function(event, ui) {
                                  $('#catalog-list').sortable('cancel');
                                }
    });
    

    $('#spinsPerWeekList').sortable({ 
                                connectWith: '#catalog-list',
                                dropOnEmpty: true,
                                remove: function(event, ui) {
                                  var data = $(ui.item).data();
                                  data.spinFrequency = $('#selectBox' + data.id + ' option:selected').text();
                                  deleteSpinPerWeekListItem(data);
                                  
                                  // re-activate song in master catalog-list
                                  $("#catalog-list").find("[data-id='" + data.id + "']").removeClass('disabled');

                                  // remove ui
                                  $(ui.item).remove();
                                },
                                receive: function(event, ui) {
                                  var data = $(ui.item).data();
                                  var html = buildSpinPerWeekListItem(data);
                                  data.spinFrequency = $('#selectBox' + ui.item.data().id + ' option:selected').text();

                                  $(ui.item).after(html);
                                  $('#catalog-list').sortable('cancel');
                                  $(ui.item).addClass('disabled');
                                  $.ajax({
                                    type: "POST",
                                    dataType: "json",
                                    url: '/stations/playlist/create_spin_frequency',
                                    contentType: 'application/json',
                                    data: JSON.stringify({ song_id: data.id,
                                                          spinFrequency: data.spinFrequency }),
                                    success: function(result) {
                                      console.log('Success! Created!');
                                      console.log(result);
                                    }
                                  });
                                }
                              });

    $('#spinsPerWeekList li').dblclick(function() {
      var data = $(this).data();
      deleteSpinPerWeekListItem(data);
      $("#catalog-list").find("[data-id='" + data.id + "']").removeClass('disabled');
      $(this).remove();
    })
  
    buildSpinPerWeekListItem = function(attrs) {
      var html = '<li data-searchString="' + attrs.title + ' ' + attrs.artist + '" ' +
                  'data-id="' + attrs.id + '" ' + 
                  'data-echonest_id="' + attrs.echonest_id + '" ' +  
                  'data-artist="' + attrs.artist + '" ' +
                  'data-title="' + attrs.title + '">' + 
                  '<span class="songlist-title">' + attrs.title + '</span>' +
                  '<span class="songlist-artist">' + attrs.artist + '</span>' +
                  '<select id="selectBox' + attrs.id + '" class="rotationSelect">' +
                    '<option value="Heavy">Heavy</option>' +
                    '<option value="Medium" selected>Medium</option>' +
                    '<option value="Light">Light</option>' +
                  '/<select>' + 
                  '</li>';
      return html;
    }

    
    deleteSpinPerWeekListItem = function(data) {
      $.ajax({
        type: "DELETE",
        dataType: "json",
        url: '/stations/playlist/delete_spin_frequency',
        contentType: 'application/json',
        data: JSON.stringify({ song_id: data.id,
                              spinFrequency: data.spinFrequency }),
        success: function(result) {
          console.log('Sucess! Deleted!');
          console.log(result);
        }
      });
    }

    // mark duplicates 'disabled' on load
    $('#spinsPerWeekList li').each( function(i) {
      var id = $(this).attr('data-id');
      $("#catalog-list").find("[data-id='" + id + "']").addClass('disabled');
    });
  }




})();