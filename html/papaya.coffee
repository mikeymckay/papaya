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
      <span class='phoneme-button button meta'>delete</span>
      <span class='phoneme-button button meta'>clear</span>
      <span id='shift' class='phoneme-button button meta'>shift</span>
      <span id='playSounds' class='phoneme-button button meta'>play</span>
      <br/>
      <br/>
      <span id='record-start-stop' class='button record'>record my voice</span>
      <span id='record-play' class='button record'>play my voice</span>
    "

  @updateCreatedWordsDivSize = ->
    if $(window).width() > $(window).height()
      heightMultiplier = .7
    else
      heightMultiplier = .8

    $('#createdWords').css
      width: $(window).width()-20
      height: $(window).height()*heightMultiplier

  @play = (filename) ->
    if Papaya.onPhonegap()
      Papaya.media?.release()
      Papaya.media = new Media("/android_asset/www/sounds/#{$("a.language.selected").text()}/#{filename}")
      Papaya.media.play()
    else
      $("#jplayer").jPlayer("setMedia",{mp3: "sounds/#{$("a.language.selected").text()}/#{filename}"})
      $("#jplayer").jPlayer("play")

class Router extends Backbone.Router
  routes:
    "": "default"
    "joinPhonemes": "joinPhonemes"
    "availablePhonemes": "availablePhonemes"
    "listenPhonemes": "listenPhonemes"
    "kiswhahili": "kiswhahili"
    "english": "english"

  updateLanguage: () ->
    Papaya.updatePhonemes()
    $(".phoneme-selector").hide()
    $(".created-words").hide()
    $("span.meta").hide()
    $(".listen-phonemes").hide()
    $("span.record").hide()
    $("#voice-selector").hide()

  kiswhahili: () ->
    $("#english").removeClass "selected"
    $("#kiswhahili").addClass "selected"
    $("#voice-child").show()
    $('#availablePhonemes').val "m,a,u,k,t,l,n,o,w,e,i,h,s,b,y,z,g,d,j,r,f,v,sh,ny,dh,th,ch,gh,ng',ng"
    @updateLanguage()

  english: () ->
    $("#english").addClass "selected"
    $("#kiswhahili").removeClass "selected"
    $("#voice-child").hide()
    $('#availablePhonemes').val "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z"
    @updateLanguage()

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
      else if phonemePressed is "delete"
        $('#createdWords').html( $('#createdWords').text().substring(0,$('#createdWords').text().length-1) )
        $('#createdWords').boxfit()
        return
      else if phonemePressed is "shift"
        $("#shift").toggleClass "shift-active"
        return
      else if phonemePressed is "play"
        availablePhonemes = $('#availablePhonemes').val().split(/, */)
        createdWord = $('#createdWords').text()
        delay = 0
        startPosition = 0
        endPosition = createdWord.length
        while startPosition != endPosition
          phoneme = createdWord.substring(startPosition,endPosition)
          if _.contains(availablePhonemes,phoneme)
            startPosition = endPosition
            endPosition = createdWord.length
            _.delay(Papaya.play, delay, "female_#{phoneme}.mp3")
            delay += 1500
          else
            endPosition = endPosition - 1
        return

      if $("#shift").hasClass "shift-active"
        phonemePressed = phonemePressed.charAt(0).toUpperCase() + phonemePressed.slice(1)

      createdWords = $('#createdWords').text()
      $('#createdWords').html "#{createdWords}#{phonemePressed}"
      $('#createdWords').boxfit()
    when "listenPhonemes"
      phoneme = $(event.target).text()
      $("#listen-status").html phoneme

      # Use the voice + letter to look for the mp3
      filename = "#{$("#voice-selector span.selected").text().toLowerCase()}_#{phoneme}.mp3"
      Papaya.play(filename)

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

