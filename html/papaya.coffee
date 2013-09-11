maxRecordTime = 15000

# Load string inflection library
_.mixin(_.str.exports())

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
      <!--
      This works but removed in case of confusion
      <span id='playSounds' class='phoneme-button button meta'>play</span>
      -->
      <br/>
      <br/>
      <span id='recording-buttons'>
        <span id='record-start-stop' class='button record'>record my voice</span>
        <span id='record-play' style='display:none' class='button record'>play my voice</span>
      </span>
    "

    $("#record-start-stop").click ->
      if $("#record-start-stop").html() is "record my voice"
        Papaya.record()
      else
        Papaya.stop()

    $("#record-play").click ->
      if $("#record-play").html() is "play my voice"
        $("#record-play").html "stop playing my voice"
        Papaya.recorder.play
          done: ->
            $("#record-play").removeClass "playing"
            $("#record-play").html "play my voice"
      else
        $("#record-play").removeClass "playing"
        $("#record-play").html "play my voice"
        Papaya.recorder.stop()

  @updateCreatedWordsDivSize = ->
    if $(window).width() > $(window).height()
      heightMultiplier = .6
    else
      heightMultiplier = .7

    $('#createdWords').css
      width: $(window).width()-20
      height: $(window).height()*heightMultiplier

    $('#createdWords').html $('#createdWords').text()
    $('#createdWords').boxfit()

  @play = (filename,button) ->
    if Papaya.onPhonegap()
      Papaya.media?.release()
      button.addClass("playing")
      console.log button
      Papaya.media = new Media "/android_asset/www/sounds/#{$("a.language.selected").text()}/#{filename}", ->
        button.removeClass("playing")
        console.log button
      Papaya.media.play()
    else
      $("#jplayer").jPlayer("setMedia",{mp3: "sounds/#{$("a.language.selected").text()}/#{filename}"})
      $("#jplayer").jPlayer("play")

  @record = ->
    $("#record-start-stop").addClass "recording"
    $("#record-start-stop").html "stop recording"
    Papaya.recorder.record()
    @autoStop = _.delay(@stop, maxRecordTime)

  @stop = ->
    $("#record-start-stop").removeClass "recording"
    $("#record-start-stop").html "record my voice"
    Papaya.recorder.stop()
    clearTimeout(@autoStop)

class Router extends Backbone.Router
  routes:
    "": "default"
    "joinPhonemes": "joinPhonemes"
    "availablePhonemes": "availablePhonemes"
    "listenPhonemes": "listenPhonemes"
    "language/:language" : "changeLanguage"

  updateLanguage: () ->
    Papaya.updatePhonemes()
    $(".phoneme-selector").hide()
    $(".created-words").hide()
    $("span.meta").hide()
    $(".listen-phonemes").hide()
    $("#recording-buttons").hide()
    $("#voice-selector").hide()

  changeLanguage: (language) ->
    config.languages[language].onLoad()
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
    $("#recording-buttons").hide()
    $("span.meta").show()
    $("#voice-selector").hide()

  listenPhonemes: () ->
    $("#content>div").hide()
    $(".phoneme-selector").show()
    $(".listen-phonemes").show()
    $("#recording-buttons").show()
    $("span.meta").hide()
    $("#voice-selector").show()

class RecordAudio
  constructor: ->
    @status = "stopped"
    @filename = "recording.wav"
    if Papaya.onPhonegap()
      @recordedSound = new Media @filename
    else
      Recorder.initialize
        swfSrc: "js/recorder.swf"

  record: =>
    if Papaya.onPhonegap()
      @recordedSound.startRecord()
    else
      Recorder.record()

  stop: =>
    if Papaya.onPhonegap()
      @recordedSound.stopRecord()
      @media?.stop()
    else
      Recorder.stop()
    $("#record-play").show()

  play: (options) =>
    if Papaya.onPhonegap()
      @media?.stop()
      #  Have to create a new Media object otherwise: Error calling method on NPObject
      @media = new Media @filename, options.done
      @media.play()
    else
      Recorder.play
        finished: options.done

    $("#record-play").addClass "playing"


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
      button = $(event.target)
      phoneme = button.text()
      $("#listen-status").html phoneme

      # Use the voice + letter to look for the mp3
      filename = "#{$("#voice-selector span.selected").text().toLowerCase()}_#{phoneme}.mp3"
      Papaya.play(filename,button)
      _.delay ->
        $("#listen-status").html ""
      , 1000



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

config =
  languages: {
    "Kiswahili" :
      onLoad: ->
        $("#English").removeClass "selected"
        $("#Kiswhahili").addClass "selected"
        $("#voice-child").show()
        $('#availablePhonemes').val "m,a,u,k,t,l,n,o,w,e,i,h,s,b,y,z,g,d,j,r,p,f,v,sh,ny,dh,th,ch,gh,ng',ng"
      
      
    "English" :
      onLoad: ->
        $("#English").addClass "selected"
        $("#Kiswhahili").removeClass "selected"
        $("#voice-child").hide()
        $('#availablePhonemes').val "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z"
        $("span.voice").removeClass "selected"
        $("#voice-female").addClass "selected"
  }
  default_language: "Kiswahili"

available_languages =_.keys config.languages

$("#navigation").prepend _.map(available_languages, (language) ->
    "<a id='#{language}' class='language' href='#language/#{language}'>#{language}</a>"
).join("")

config.languages[config.default_language].onLoad()

Papaya.updatePhonemes()
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
