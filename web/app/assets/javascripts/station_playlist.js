(function() {
  if ($('body.stations').length) {
    
    $('#searchbox').keyup(function() {
      var searchText = $('#searchbox').val();
      searchSonglist(searchText, ['#catalog-list']);
    });
    
  }
})();