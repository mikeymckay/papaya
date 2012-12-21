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
      <span id='record-start-stop' class='button record'>record my voice</span>
      <span id='record-play' class='button record'>play my voice</span>
    "

class Router extends Backbone.Router
  routes:
    "": "default"
    "joinPhonemes": "joinPhonemes"
    "availablePhonemes": "availablePhonemes"
    "listenPhonemes": "listenPhonemes"
    "recordPhonemes": "recordPhonemes"

  default: () ->
    $("#content>div").hide()
    $(".logo").show()

  availablePhonemes: () ->
    $("#content>div").hide()
    $(".available-phonemes").show()

  joinPhonemes: () ->
    $("#content>div").hide()
    $(".phoneme-selector").show()
    $(".created-words").show()
    $("span.record").hide()

  listenPhonemes: () ->
    $("#content>div").hide()
    $(".phoneme-selector").show()
    $(".listen-phonemes").show()
    $("span.record").show()
    $("span.meta").hide()

  recordPhonemes: () ->
    $("#content>div").hide()
    $(".phoneme-selector").show()
    $(".listen-phonemes").show()
    $(".record-phonemes").show()
    $("span.meta").hide()

class RecordAudio
  constructor: ->
    @status = "stopped"
    @filename = "recording.wav"
    if Papaya.onPhonegap()
      @recordedSound = new Media(@filename)
    else
      Recorder.initialize
        swfSrc: "js/recorder.swf"

  record: ->
    if Papaya.onPhonegap() then @recordedSound.startRecord() else Recorder.record()

  stop: ->
    if Papaya.onPhonegap() then @recordedSound.stopRecord() else Recorder.stop()

  play: ->
    #  Have to create a new Media object otherwise: Error calling method on NPObject
    if Papaya.onPhonegap() then (new Media(@filename)).play() else Recorder.play()

Papaya.updatePhonemes()

# events

$(document).on "change", "#availablePhonemes", Papaya.updatePhonemes
$(document).on "click", ".phoneme-button", (event) ->
  switch Backbone.history.fragment
    when "joinPhonemes"
      phonemePressed = $(event.target).text()
      if phonemePressed is "space"
        phonemePressed = " "
      else if phonemePressed is "clear"
        $('#createdWords').html ""
        return
      createdWords = $('#createdWords').text()
      $('#createdWords').html "#{createdWords}#{phonemePressed}"
      $('#createdWords').boxfit()
    when "listenPhonemes"
      phoneme = $(event.target).text()
      $("#listen-status").html phoneme

      # Use the voice + letter to look for the mp3
      filename = "#{$("#voice-selector div.selected").text().toLowerCase()}_#{phoneme}.mp3"
      if Papaya.onPhonegap()
        (new Media("/android_asset/www/#{filename}")).play()
      else
        $("#jplayer").jPlayer("setMedia",{mp3: filename})
        $("#jplayer").jPlayer("play")

$("#record-start-stop").click ->
  $("#recordingMessage").show()
  if $("#record-start-stop").html() is "record my voice"
    $("#record-start-stop").html "stop recording"
    Papaya.recorder.record()
  else
    $("#record-start-stop").html "record my voice"
    Papaya.recorder.stop()


$("#record-play").click ->
  $("#recordingMessage").hide()
  Papaya.recorder.play()

$("#voice-selector div").click (event) ->
  $(event.target).siblings().removeClass "selected"
  $(event.target).addClass "selected"

# five clicks within 3 seconds -> reload
###
timeOuts = []
$(document).click ->
  timeOuts.push(setTimeout ->
    timeOuts.shift()
  3000)
    
  if timeOuts.length is 5
    _.each timeOuts, (x) ->
      clearTimeout(timeOuts[x])
    timeOuts = []
    document.location.reload()
###

router = new Router()
Backbone.history.start()

$(document).ready () ->
  $("#jplayer").jPlayer
    error: (error) ->
      if error.jPlayer.error.type is "e_url"
        phoneme = $("#listen-status").text()
        filename = "#{$("#voice-selector div.selected").text().toLowerCase()}_#{phoneme}.mp3"
        $("#listen-status").append "<br><small>No sound file available (#{filename})</small>"
$('#createdWords').css
  width: $(window).width()-20
  height: $(window).height()*(3/4)

if @onPhonegap
  document.addEventListener("deviceready", ->
    Papaya.recorder = new RecordAudio()
  , false)
else
  Papaya.recorder = new RecordAudio()
