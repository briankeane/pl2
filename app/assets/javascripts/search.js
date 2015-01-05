(function(div){
  // ************* searchSonglist(searchText, listArray) ******
  // **********************************************************
  // *  searchSonglist hides all list-items that do not match *
  // *    the searchText.  Takes searchText and an array of   *
  // *    lists to search                                     *
  // **********************************************************
  searchSonglist = function(searchString, listArray) { 
    if (searchString.trim() != '') {
      $.ajax({
        type: 'GET',
        dataType: 'json',
        url: '/songs/get_songs_by_keywords',
        contentType: 'application/json',
        data: { searchString: searchString },
        success: function(result){
          if ($('#searchbox').val() == searchString) {
            var renderedSongs = result.map(function(song) {
              return renderCatalogLi(song);
            });
            
            $('#catalog-list').empty();
            renderedSongs.forEach(function(song) {
              $('#catalog-list').append(song);
            });
          }
        }
      });
    }
  };


  renderCatalogLi = function(song) {
    var html = '<li data-id="' + song.id + '">' + 
                  '<span class="songlist-title">' + song.title + '</span>' +
                  '<span class="songlist-artist">' + song.artist + '</span>' +
                '</li>';
    return html;
  }

})();