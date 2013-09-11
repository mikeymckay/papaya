// Generated by CoffeeScript 1.6.2
var Papaya, RecordAudio, Router, available_languages, clickortouch, config, maxRecordTime, router, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

maxRecordTime = 15000;

_.mixin(_.str.exports());

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
    $('#phonemeSelector').append("      <span class='phoneme-button button meta'>space</span>      <span class='phoneme-button button meta'>delete</span>      <span class='phoneme-button button meta'>clear</span>      <span id='shift' class='phoneme-button button meta'>shift</span>      <!--      This works but removed in case of confusion      <span id='playSounds' class='phoneme-button button meta'>play</span>      -->      <br/>      <br/>      <span id='recording-buttons'>        <span id='record-start-stop' class='button record'>record my voice</span>        <span id='record-play' style='display:none' class='button record'>play my voice</span>      </span>    ");
    $("#record-start-stop").click(function() {
      if ($("#record-start-stop").html() === "record my voice") {
        return Papaya.record();
      } else {
        return Papaya.stop();
      }
    });
    return $("#record-play").click(function() {
      if ($("#record-play").html() === "play my voice") {
        $("#record-play").html("stop playing my voice");
        return Papaya.recorder.play({
          done: function() {
            $("#record-play").removeClass("playing");
            return $("#record-play").html("play my voice");
          }
        });
      } else {
        $("#record-play").removeClass("playing");
        $("#record-play").html("play my voice");
        return Papaya.recorder.stop();
      }
    });
  };

  Papaya.updateCreatedWordsDivSize = function() {
    var heightMultiplier;

    if ($(window).width() > $(window).height()) {
      heightMultiplier = .6;
    } else {
      heightMultiplier = .7;
    }
    $('#createdWords').css({
      width: $(window).width() - 20,
      height: $(window).height() * heightMultiplier
    });
    $('#createdWords').html($('#createdWords').text());
    return $('#createdWords').boxfit();
  };

  Papaya.play = function(filename, button) {
    var _ref;

    if (Papaya.onPhonegap()) {
      if ((_ref = Papaya.media) != null) {
        _ref.release();
      }
      button.addClass("playing");
      console.log(button);
      Papaya.media = new Media("/android_asset/www/sounds/" + ($("a.language.selected").text()) + "/" + filename, function() {
        button.removeClass("playing");
        return console.log(button);
      });
      return Papaya.media.play();
    } else {
      $("#jplayer").jPlayer("setMedia", {
        mp3: "sounds/" + ($("a.language.selected").text()) + "/" + filename
      });
      return $("#jplayer").jPlayer("play");
    }
  };

  Papaya.record = function() {
    $("#record-start-stop").addClass("recording");
    $("#record-start-stop").html("stop recording");
    Papaya.recorder.record();
    return this.autoStop = _.delay(this.stop, maxRecordTime);
  };

  Papaya.stop = function() {
    $("#record-start-stop").removeClass("recording");
    $("#record-start-stop").html("record my voice");
    Papaya.recorder.stop();
    return clearTimeout(this.autoStop);
  };

  return Papaya;

})();

Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    _ref = Router.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Router.prototype.routes = {
    "": "default",
    "joinPhonemes": "joinPhonemes",
    "availablePhonemes": "availablePhonemes",
    "listenPhonemes": "listenPhonemes",
    "language/:language": "changeLanguage"
  };

  Router.prototype.updateLanguage = function() {
    Papaya.updatePhonemes();
    $(".phoneme-selector").hide();
    $(".created-words").hide();
    $("span.meta").hide();
    $(".listen-phonemes").hide();
    $("#recording-buttons").hide();
    return $("#voice-selector").hide();
  };

  Router.prototype.changeLanguage = function(language) {
    config.languages[language].onLoad();
    return this.updateLanguage();
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
    $("#recording-buttons").hide();
    $("span.meta").show();
    return $("#voice-selector").hide();
  };

  Router.prototype.listenPhonemes = function() {
    $("#content>div").hide();
    $(".phoneme-selector").show();
    $(".listen-phonemes").show();
    $("#recording-buttons").show();
    $("span.meta").hide();
    return $("#voice-selector").show();
  };

  return Router;

})(Backbone.Router);

RecordAudio = (function() {
  function RecordAudio() {
    this.play = __bind(this.play, this);
    this.stop = __bind(this.stop, this);
    this.record = __bind(this.record, this);    this.status = "stopped";
    this.filename = "recording.wav";
    if (Papaya.onPhonegap()) {
      this.recordedSound = new Media(this.filename);
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
    var _ref1;

    if (Papaya.onPhonegap()) {
      this.recordedSound.stopRecord();
      if ((_ref1 = this.media) != null) {
        _ref1.stop();
      }
    } else {
      Recorder.stop();
    }
    return $("#record-play").show();
  };

  RecordAudio.prototype.play = function(options) {
    var _ref1;

    if (Papaya.onPhonegap()) {
      if ((_ref1 = this.media) != null) {
        _ref1.stop();
      }
      this.media = new Media(this.filename, options.done);
      this.media.play();
    } else {
      Recorder.play({
        finished: options.done
      });
    }
    return $("#record-play").addClass("playing");
  };

  return RecordAudio;

})();

$(document).on("change", "#availablePhonemes", Papaya.updatePhonemes);

clickortouch = Papaya.onPhonegap() ? "touchend" : "click";

$(document).on(clickortouch, ".phoneme-button", function(event) {
  var availablePhonemes, button, createdWord, createdWords, delay, endPosition, filename, phoneme, phonemePressed, startPosition;

  switch (Backbone.history.fragment) {
    case "joinPhonemes":
      phonemePressed = $(event.target).text();
      if (phonemePressed === "space") {
        phonemePressed = " ";
      } else if (phonemePressed === "clear") {
        $('#createdWords').html("");
        return;
      } else if (phonemePressed === "delete") {
        $('#createdWords').html($('#createdWords').text().substring(0, $('#createdWords').text().length - 1));
        $('#createdWords').boxfit();
        return;
      } else if (phonemePressed === "shift") {
        $("#shift").toggleClass("shift-active");
        return;
      } else if (phonemePressed === "play") {
        availablePhonemes = $('#availablePhonemes').val().split(/, */);
        createdWord = $('#createdWords').text();
        delay = 0;
        startPosition = 0;
        endPosition = createdWord.length;
        while (startPosition !== endPosition) {
          phoneme = createdWord.substring(startPosition, endPosition);
          if (_.contains(availablePhonemes, phoneme)) {
            startPosition = endPosition;
            endPosition = createdWord.length;
            _.delay(Papaya.play, delay, "female_" + phoneme + ".mp3");
            delay += 1500;
          } else {
            endPosition = endPosition - 1;
          }
        }
        return;
      }
      if ($("#shift").hasClass("shift-active")) {
        phonemePressed = phonemePressed.charAt(0).toUpperCase() + phonemePressed.slice(1);
      }
      createdWords = $('#createdWords').text();
      $('#createdWords').html("" + createdWords + phonemePressed);
      return $('#createdWords').boxfit();
    case "listenPhonemes":
      button = $(event.target);
      phoneme = button.text();
      $("#listen-status").html(phoneme);
      filename = "" + ($("#voice-selector span.selected").text().toLowerCase()) + "_" + phoneme + ".mp3";
      Papaya.play(filename, button);
      return _.delay(function() {
        return $("#listen-status").html("");
      }, 1000);
  }
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

config = {
  languages: {
    "Kiswahili": {
      onLoad: function() {
        $("#English").removeClass("selected");
        $("#Kiswhahili").addClass("selected");
        $("#voice-child").show();
        return $('#availablePhonemes').val("m,a,u,k,t,l,n,o,w,e,i,h,s,b,y,z,g,d,j,r,p,f,v,sh,ny,dh,th,ch,gh,ng',ng");
      }
    },
    "English": {
      onLoad: function() {
        $("#English").addClass("selected");
        $("#Kiswhahili").removeClass("selected");
        $("#voice-child").hide();
        $('#availablePhonemes').val("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z");
        $("span.voice").removeClass("selected");
        return $("#voice-female").addClass("selected");
      }
    }
  },
  default_language: "Kiswahili"
};

available_languages = _.keys(config.languages);

$("#navigation").prepend(_.map(available_languages, function(language) {
  return "<a id='" + language + "' class='language' href='#language/" + language + "'>" + language + "</a>";
}).join(""));

config.languages[config.default_language].onLoad();

Papaya.updatePhonemes();

Papaya.updateCreatedWordsDivSize();

window.addEventListener("resize", function() {
  return Papaya.updateCreatedWordsDivSize();
}, false);

if (Papaya.onPhonegap()) {
  document.addEventListener("deviceready", function() {
    navigator.splashscreen.hide();
    return Papaya.recorder = new RecordAudio();
  }, false);
} else {
  Papaya.recorder = new RecordAudio();
}
