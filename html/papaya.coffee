class Papaya
  @onPhonegap = ->
    document.URL.indexOf( 'http://' ) is -1 && document.URL.indexOf( 'https://' ) is -1

  @updatePhonemes = ->
    phonemes = $("#availablePhonemes").val().split(/, */)
    $('#phonemeSelector').html _.map(phonemes, (phoneme) ->
      "<span class='phoneme-button button'>#{phoneme}</span> "
    ).join("")
    $('#phonemeSelector').append "
      <span class='phoneme-button button meta'>space</span>
      <span class='phoneme-button button meta'>clear</span>
      <span id='shift' class='phoneme-button button meta'>shift</span>
      <br/>
      <br/>
      <span id='record-start-stop' class='button record'>record my voice</span>
      <span id='record-play' class='button record'>play my voice</span>
    "

  @updateCreatedWordsDivSize = ->
    $('#createdWords').css
      width: $(window).width()-20
      height: $(window).height()/2
    console.log "w:"+ $('#createdWords').css("width")
    console.log "h:"+ $('#createdWords').css("height")

class Router extends Backbone.Router
  routes:
    "": "default"
    "joinPhonemes": "joinPhonemes"
    "availablePhonemes": "availablePhonemes"
    "listenPhonemes": "listenPhonemes"

  default: () ->
    $("#content>div").hide()
    $(".listen-phonemes").hide()
    $(".logo").show()
    $("#voice-selector").hide()

  availablePhonemes: () ->
    $("#content>div").hide()
    $(".listen-phonemes").hide()
    $(".available-phonemes").show()
    $("#voice-selector").hide()

  joinPhonemes: () ->
    $("#content>div").hide()
    $(".listen-phonemes").hide()
    $(".phoneme-selector").show()
    $(".created-words").show()
    $("span.record").hide()
    $("span.meta").show()
    $("#voice-selector").hide()

  listenPhonemes: () ->
    $("#content>div").hide()
    $(".phoneme-selector").show()
    $(".listen-phonemes").show()
    $("span.record").show()
    $("span.meta").hide()
    $("#voice-selector").show()

class RecordAudio
  constructor: ->
    @status = "stopped"
    @filename = "recording.wav"
    if Papaya.onPhonegap()
      @recordedSound = new Media(@filename)
    else
      Recorder.initialize
        swfSrc: "js/recorder.swf"

  record: =>
    if Papaya.onPhonegap() then @recordedSound.startRecord() else Recorder.record()

  stop: =>
    if Papaya.onPhonegap() then @recordedSound.stopRecord() else Recorder.stop()

  play: =>
    #  Have to create a new Media object otherwise: Error calling method on NPObject
    if Papaya.onPhonegap() then (new Media(@filename)).play() else Recorder.play()

Papaya.updatePhonemes()

# events

$(document).on "change", "#availablePhonemes", Papaya.updatePhonemes

clickortouch = if Papaya.onPhonegap() then "touchend" else "click"

$(document).on clickortouch, ".phoneme-button", (event) ->
  switch Backbone.history.fragment
    when "joinPhonemes"
      phonemePressed = $(event.target).text()
      if phonemePressed is "space"
        phonemePressed = " "
      else if phonemePressed is "clear"
        $('#createdWords').html ""
        return
      else if phonemePressed is "shift"
        $("#shift").toggleClass "shift-active"
        return

      if $("#shift").hasClass "shift-active"
        console.log "ASDAS"
        phonemePressed = phonemePressed.charAt(0).toUpperCase() + phonemePressed.slice(1)

      createdWords = $('#createdWords').text()
      $('#createdWords').html "#{createdWords}#{phonemePressed}"
      $('#createdWords').boxfit()
    when "listenPhonemes"
      phoneme = $(event.target).text()
      $("#listen-status").html phoneme

      # Use the voice + letter to look for the mp3
      filename = "#{$("#voice-selector span.selected").text().toLowerCase()}_#{phoneme}.mp3"
      if Papaya.onPhonegap()
        Papaya.media?.release()
        Papaya.media = new Media("/android_asset/www/sounds/#{filename}")
        Papaya.media.play()
      else
        console.log "Not phonegap"
        $("#jplayer").jPlayer("setMedia",{mp3: "sounds/#{filename}"})
        $("#jplayer").jPlayer("play")

$("#record-start-stop").click ->
  $("#recordingMessage").show()
  if $("#record-start-stop").html() is "record my voice"
    $("#record-start-stop").addClass "recording"
    $("#record-start-stop").html "stop recording"
    Papaya.recorder.record()
  else
    $("#record-start-stop").removeClass "recording"
    $("#record-start-stop").html "record my voice"
    Papaya.recorder.stop()

$("#record-play").click ->
  $("#recordingMessage").hide()
  Papaya.recorder.play()

$("#voice-selector span").click (event) ->
  $(event.target).siblings().removeClass "selected"
  $(event.target).addClass "selected"

router = new Router()
Backbone.history.start()

$(document).ready () ->
  $("#jplayer").jPlayer
    error: (error) ->
      if error.jPlayer.error.type is "e_url"
        phoneme = $("#listen-status").text()
        filename = "#{$("#voice-selector span.selected").text().toLowerCase()}_#{phoneme}.mp3"
        $("#listen-status").append "<br><span style='font-size:20px'>No sound file available (#{filename})</span>"

Papaya.updateCreatedWordsDivSize()

window.addEventListener("resize", ->
  Papaya.updateCreatedWordsDivSize()
, false)

if Papaya.onPhonegap()
  document.addEventListener("deviceready", ->
    navigator.splashscreen.hide()
    Papaya.recorder = new RecordAudio()
  , false)
else
  Papaya.recorder = new RecordAudio()

