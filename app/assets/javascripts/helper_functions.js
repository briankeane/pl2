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
};

// taken from http://stackoverflow.com/questions/2400935/browser-detection-in-javascript
// returns the browser and version
navigator.sayswho= (function(){
    var ua= navigator.userAgent, tem, 
    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if(/trident/i.test(M[1])){
        tem=  /\brv[ :]+(\d+)/g.exec(ua) || [];
        return 'IE '+(tem[1] || '');
    }
    if(M[1] === 'Chrome'){
        tem= ua.match(/\bOPR\/(\d+)/);
        if(tem!== null) return 'Opera '+tem[1];
    }
    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
    if((tem= ua.match(/version\/(\d+)/i))!== null) M.splice(1, 1, tem[1]);
    return M.join(' ');
})();


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


// *********************************************
// *          getSpinByCurrentPosition         *
// *                                           *
// *  -- spinInfo: lastCurrentPosition,        *
// *               currentPosition,            *
// *               stationId,                  *
// *               stationId                  *
// *********************************************
var getSpinByCurrentPosition = function(spinInfo, callback) {
  $.ajax({
        type: 'GET',
        dataType: 'json',
        url: '/stations/get_spin_by_current_position',
        contentType: 'application/json',
        data: spinInfo,
        success: callback
  });
};

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

// functions for editing spins_per_week
var createSpinPerWeekListItem = function(data) {
  $.ajax({
    type: "POST",
    dataType: "json",
    url: '/stations/playlist/create_spin_frequency',
    contentType: 'application/json',
    data: JSON.stringify({ song_id: data.id,
                          spins_per_week: data.spinFrequency }),
    success: function(result) {
      if (result.table.station) {
        gon.currentStation = result.station;
      }
    }
  });
};

var getAudioQueueIndexByKey = function(key) {
  for (var i=0; i<gon.audioQueue.length; i++) {
    if (gon.audioQueue[i].key === key) {
        return i;
    }
  }
};

var onWakeFromSleep = function(callback) {
  // detect sleep
  var thenTime = (new Date()).getTime();
  setInterval(function() {
    if (((new Date()).getTime() - thenTime) > 4000) {  //4 secs
      callback();
    }
    thenTime = (new Date()).getTime();
  }, 2000);
};

