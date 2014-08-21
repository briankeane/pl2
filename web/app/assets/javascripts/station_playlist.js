(function() {
  if ($('body.stations').length) {
    
    $('#searchbox').keyup(function() {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#catalog-list']);
    });
    
    $('#catalog-list').sortable({ connectWith: '#spinsPerWeekList',
                                helper: 'clone',
                                widgets: ['zebra'],
                                cancel: ".disabled"
    });
    

    $('#spinsPerWeekList').sortable({ 
                                dropOnEmpty: true,
                                receive: function(event, ui) {
                                  $(ui.item).after("<li>THIS IS IT</li>");
                                  $('#catalog-list').sortable('cancel');
                                  $(ui.item).addClass('disabled');
                                }
                              });


  
    buildSpinPerWeekListItem = function(attrs) {
      var html = '<li data-searchString="' + attrs.title + ' ' + attrs.artist + '" ' +
                  'data-id="' + attrs.songID + '">' + 
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

    

    // mark duplicates 'disabled' on load

    $('#spinsPerWeekList li').each( function(i) {
      var id = $(this).attr('data-id');
      $("#catalog-list").find("[data-id='" + id + "']").addClass('disabled');
    });
  }




})();