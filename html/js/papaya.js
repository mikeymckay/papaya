// Generated by CoffeeScript 1.4.0
var Papaya, RecordAudio, Router, clickortouch, router,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Papaya = (function() {

  function Papaya() {}

  Papaya.onPhonegap = function() {
    return document.URL.indexOf('http://') === -1 && document.URL.indexOf('https://') === -1;
  };

  Papaya.updatePhonemes = function() {
    var phonemes;
    phonemes = $("#availablePhonemes").val().split(/, */);
    $('#phonemeSelector').html(_.map(phonemes, function(phoneme) {
      return "<span class='phoneme-button button'>" + phoneme + "</span> ";
    }).join(""));
    return $('#phonemeSelector').append("      <span class='phoneme-button button meta'>space</span>      <span class='phoneme-button button meta'>clear</span>      <span id='shift' class='phoneme-button button meta'>shift</span>      <br/>      <br/>      <span id='record-start-stop' class='button record'>record my voice</span>      <span id='record-play' class='button record'>play my voice</span>    ");
  };

  Papaya.updateCreatedWordsDivSize = function() {
    $('#createdWords').css({
      width: $(window).width() - 20,
      height: $(window).height() / 2
    });
    console.log("w:" + $('#createdWords').css("width"));
    return console.log("h:" + $('#createdWords').css("height"));
  };

  return Papaya;

})();

Router = (function(_super) {

  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    "": "default",
    "joinPhonemes": "joinPhonemes",
    "availablePhonemes": "availablePhonemes",
    "listenPhonemes": "listenPhonemes"
  };

  Router.prototype["default"] = function() {
    $("#content>div").hide();
    $(".listen-phonemes").hide();
    $(".logo").show();
    return $("#voice-selector").hide();
  };

  Router.prototype.availablePhonemes = function() {
    $("#content>div").hide();
    $(".listen-phonemes").hide();
    $(".available-phonemes").show();
    return $("#voice-selector").hide();
  };

  Router.prototype.joinPhonemes = function() {
    $("#content>div").hide();
    $(".listen-phonemes").hide();
    $(".phoneme-selector").show();
    $(".created-words").show();
    $("span.record").hide();
    $("span.meta").show();
    return $("#voice-selector").hide();
  };

  Router.prototype.listenPhonemes = function() {
    $("#content>div").hide();
    $(".phoneme-selector").show();
    $(".listen-phonemes").show();
    $("span.record").show();
    $("span.meta").hide();
    return $("#voice-selector").show();
  };

  return Router;

})(Backbone.Router);

RecordAudio = (function() {

  function RecordAudio() {
    this.play = __bind(this.play, this);

    this.stop = __bind(this.stop, this);

    this.record = __bind(this.record, this);
    this.status = "stopped";
    this.filename = "recording.wav";
    if (Papaya.onPhonegap()) {
      this.recordedSound = new Media(this.filename);
      console.log("created recordedSound");
    } else {
      Recorder.initialize({
        swfSrc: "js/recorder.swf"
      });
    }
  }

  RecordAudio.prototype.record = function() {
    if (Papaya.onPhonegap()) {
      return this.recordedSound.startRecord();
    } else {
      return Recorder.record();
    }
  };

  RecordAudio.prototype.stop = function() {
    if (Papaya.onPhonegap()) {
      return this.recordedSound.stopRecord();
    } else {
      return Recorder.stop();
    }
  };

  RecordAudio.prototype.play = function() {
    if (Papaya.onPhonegap()) {
      return (new Media(this.filename)).play();
    } else {
      return Recorder.play();
    }
  };

  return RecordAudio;

})();

Papaya.updatePhonemes();

$(document).on("change", "#availablePhonemes", Papaya.updatePhonemes);

clickortouch = Papaya.onPhonegap() ? "touchend" : "click";

$(document).on(clickortouch, ".phoneme-button", function(event) {
  var createdWords, filename, phoneme, phonemePressed;
  switch (Backbone.history.fragment) {
    case "joinPhonemes":
      phonemePressed = $(event.target).text();
      if (phonemePressed === "space") {
        phonemePressed = " ";
      } else if (phonemePressed === "clear") {
        $('#createdWords').html("");
        return;
      } else if (phonemePressed === "shift") {
        $("#shift").toggleClass("shift-active");
        return;
      }
      if ($("#shift").hasClass("shift-active")) {
        console.log("ASDAS");
        phonemePressed = phonemePressed.charAt(0).toUpperCase() + phonemePressed.slice(1);
      }
      createdWords = $('#createdWords').text();
      $('#createdWords').html("" + createdWords + phonemePressed);
      return $('#createdWords').boxfit();
    case "listenPhonemes":
      phoneme = $(event.target).text();
      $("#listen-status").html(phoneme);
      filename = "" + ($("#voice-selector span.selected").text().toLowerCase()) + "_" + phoneme + ".mp3";
      if (Papaya.onPhonegap()) {
        return (new Media("/android_asset/www/sounds/" + filename)).play();
      } else {
        $("#jplayer").jPlayer("setMedia", {
          mp3: "sounds/" + filename
        });
        return $("#jplayer").jPlayer("play");
      }
  }
});

$("#record-start-stop").click(function() {
  $("#recordingMessage").show();
  if ($("#record-start-stop").html() === "record my voice") {
    $("#record-start-stop").html("stop recording");
    return Papaya.recorder.record();
  } else {
    $("#record-start-stop").html("record my voice");
    return Papaya.recorder.stop();
  }
});

$("#record-play").click(function() {
  $("#recordingMessage").hide();
  return Papaya.recorder.play();
});

$("#voice-selector span").click(function(event) {
  $(event.target).siblings().removeClass("selected");
  return $(event.target).addClass("selected");
});

router = new Router();

Backbone.history.start();

$(document).ready(function() {
  return $("#jplayer").jPlayer({
    error: function(error) {
      var filename, phoneme;
      if (error.jPlayer.error.type === "e_url") {
        phoneme = $("#listen-status").text();
        filename = "" + ($("#voice-selector span.selected").text().toLowerCase()) + "_" + phoneme + ".mp3";
        return $("#listen-status").append("<br><span style='font-size:20px'>No sound file available (" + filename + ")</span>");
      }
    }
  });
});

Papaya.updateCreatedWordsDivSize();

window.addEventListener("resize", function() {
  return Papaya.updateCreatedWordsDivSize();
}, false);

if (Papaya.onPhonegap()) {
  document.addEventListener("deviceready", function() {
    return Papaya.recorder = new RecordAudio();
  }, false);
} else {
  Papaya.recorder = new RecordAudio();
}
