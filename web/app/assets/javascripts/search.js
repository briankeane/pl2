(function(div){
  // ************* searchSonglist(searchText, listArray) ******
  // **********************************************************
  // *  searchSonglist hides all list-items that do not match *
  // *    the searchText.  Takes searchText and an array of   *
  // *    lists to search                                     *
  // **********************************************************
  searchSonglist = function(searchText, listArray) { 
    var searchString = searchText.toLowerCase();

    for(var j=0; j<listArray.length; j++){
      var fullList = $(listArray[j] + ' li');

      for (var i=0; i<fullList.length; i++) {
        var attr = fullList.eq(i).attr('data-searchString');
        if  (typeof attr !== 'undefined' && attr !== false) {
          var targetString = fullList.eq(i).attr("data-searchString").toLowerCase();

          if (targetString.indexOf(searchString) == -1) {
            fullList.eq(i).hide();
          } else {
            fullList.eq(i).show();
          }
        }
      }
    }
  } 

})();