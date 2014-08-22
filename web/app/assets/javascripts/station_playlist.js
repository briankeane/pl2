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
                                dropOnEmpty: true,
                                receive: function(event, ui) {
                                  var data = $(ui.item).data();
                                  var html = buildSpinPerWeekListItem(data);

                                  $(ui.item).after(html);
                                  $('#catalog-list').sortable('cancel');
                                  $(ui.item).addClass('disabled');
                                }
                              });


  
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

    

    // mark duplicates 'disabled' on load
    $('#spinsPerWeekList li').each( function(i) {
      var id = $(this).attr('data-id');
      $("#catalog-list").find("[data-id='" + id + "']").addClass('disabled');
    });
  }




})();