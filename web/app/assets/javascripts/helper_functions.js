var formatTime = function(time) {
  var hours = time.getHours();
  var minutes = time.getMinutes();
  var seconds = time.getSeconds();

  if (hours <= 12) {
    var amPm = 'am';
  } else {
    hours = hours - 12;
    var amPm = 'pm';
  }

  if (minutes < 10) {
    var minutes = "0" + minutes;
  }

  if (seconds < 10) {
    var seconds = "0" + seconds;
  }

  return (hours + ':' + minutes + ':' + seconds + ' ' + amPm);
} 

function formatSongFromMS(milliseconds) {
  var totalSeconds = milliseconds/1000;
  var secs = Math.floor(totalSeconds % 60) ;
  var mins = Math.floor((totalSeconds - secs)/60);
  var hrs = Math.floor(((totalSeconds - secs - (mins * 60))/60));

  if (secs < 10) {
    secs = "0" + secs;
  }

  if (hrs > 0) {
    return '' + hrs + ':' + mins + ':' + secs;
  } else {
    return '' + mins + ':' + secs;
  }
}

/**
* Generates a GUID string.
* @returns {String} The generated GUID.
* @example af8a8416-6e18-a307-bd9c-f2c947bbb3aa
* @author Slavik Meltser (slavik@meltser.info).
* @link http://slavik.meltser.info/?p=142
*/
function guid() {
    function _p8(s) {
        var p = (Math.random().toString(16)+"000000000").substr(2,8);
        return s ? "-" + p.substr(0,4) + "-" + p.substr(4,4) : p ;
    }
    return _p8() + _p8(true) + _p8(true) + _p8();
}
