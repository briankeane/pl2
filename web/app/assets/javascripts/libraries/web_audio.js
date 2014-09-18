var webAudio = function() {

  // Start off by initializing a new context.
  context = new webkitAudioContext();

  // shim layer with setTimeout fallback
  window.requestAnimFrame = (function(){
  return  window.requestAnimationFrame       ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.oRequestAnimationFrame      ||
    window.msRequestAnimationFrame     ||
    function( callback ){
    window.setTimeout(callback, 1000 / 60);
  };
  })();


  function playSound(buffer, time) {
    var source = context.createBufferSource();
    source.buffer = buffer;
    source.connect(context.destination);
    source.start(time);
  }

  function loadSounds(obj, soundMap) {
    // Array-ify
    var names = [];
    var paths = [];
    for (var name in soundMap) {
      var path = soundMap[name];
      names.push(name);
      paths.push(path);
    }
    bufferLoader = new BufferLoader(context, paths, function(bufferList) {
      for (var i = 0; i < bufferList.length; i++) {
        var buffer = bufferList[i];
        var name = names[i];
        obj[name] = buffer;
      }
    });
    bufferLoader.load();
  }



  // This is the default bufferloader from webaudio.com
  function BufferLoader(context, urlList, callback) {
    this.context = context;
    this.urlList = urlList;
    this.onload = callback;
    this.bufferList = new Array();
    this.loadCount = 0;
  }

  BufferLoader.prototype.loadBuffer = function(url, index) {
    // Load buffer asynchronously
    var request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.responseType = "arraybuffer";

    var loader = this;

    request.onload = function() {
      // Asynchronously decode the audio file data in request.response
      loader.context.decodeAudioData(
        request.response,
        function(buffer) {
          if (!buffer) {
            alert('error decoding file data: ' + url);
            return;
          }
          loader.bufferList[index] = buffer;
          if (++loader.loadCount == loader.urlList.length)
            loader.onload(loader.bufferList);
        },
        function(error) {
          console.error('decodeAudioData error', error);
        }
      );
    }

    request.onerror = function() {
      alert('BufferLoader: XHR error');
    }

    request.send();
  };

  BufferLoader.prototype.load = function() {
    for (var i = 0; i < this.urlList.length; ++i)
    this.loadBuffer(this.urlList[i], i);
  };




  // MY STUFF NOW..... FOR RECORDING
  function getLiveInput() {
    //get the audio stream
    navigator.webkitGetUserMedia({ audio: true }, onStream, onStreamError);
  };

  function onStream(stream) {
    // Wrap a Node around the stream
    var input = context.createMediaStreamSource(stream);

    // connect it to a filter
    var filter = context.createBiquadFilter();
    filter.frequency.value = 60.0;
    filter.type = filter.NOTCH;
    filter.Q = 10.0;

    var analyser = context.createAnalyser();

    // Connect graph
    input.connect(filter);
    filter.connect(analyser);

    // Set up animation
    requestAnimationFrame(render);
  };



  // see if any of these work (diff browsers)
  var contextClass = (window.AudioContext ||
                      window.webkitAudioContext ||
                      window.mozAudioContext ||
                      window.oAudioContext ||
                      window.msAudioContext);

  if (contextClass) {
    // webAudio is available so init it
    var context = new contextClass();
  } else {
    alert("You can't record with this browser... time to UPGRADE, bitch.");
  }

  var bufferLoader = new BufferLoader(
    context,
    [
    '../../../../Desktop/oldwithyou.mp3'
    ],
    finishedLoading
    );

  bufferLoader.load();

  function finishedLoading(bufferList) {
    var source1 = context.createBufferSource();
    source1.buffer = bufferList[0];

    source1.connect(context.destination);
    source1.start(0);
  }



  return {
    "finishedLoading": finishedLoading
  };
}
