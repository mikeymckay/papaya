appName = "Papaya"
directoryPath = "/sdcard/#{appName}"
serverPath = "http://papaya.tangerinecentral.org"
defaultLanguages = ["English","Kiswahili"]

# Load string inflection library
_.mixin(_.str.exports())

class Papaya

  @updateLanguages = () ->
    available_languages = _.keys Papaya.config.languages

    $("#languageSelector").html _.map(available_languages, (language) ->
        "<a id='#{language}' class='language' href='#language/#{language}'>#{language}</a>"
    ).join("")


  @loadConfig = (options) ->
    pathToConfig = "config.json"
    if Papaya.onPhonegap()
      pathToConfig = "file://#{directoryPath}/#{pathToConfig}"

    $.ajax
      url: pathToConfig
      dataType: "json"
      error: (result) ->
        console.log "Error downloading config file from '#{pathToConfig}': #{JSON.stringify(result)}"
        options?.error?(result)
      success: (result) =>
        Papaya.config = result
        console.log "Successfully loaded config from '#{pathToConfig}'. Using config: #{JSON.stringify(Papaya.config)}"
        Papaya.updateLanguages()
        options?.success?(result)

  # Consider using ajax instead
  @downloadLanguageJson = (languages, success) ->
    url = "#{serverPath}/json_package?languages=#{languages.join(",")}"
    targetFile = "#{directoryPath}/config.json"
    fileTransfer = new FileTransfer()
    fileTransfer.download url, targetFile,
      (data) =>
        console.log "Copied #{url} to #{targetFile}"
        success(data)
      (error) ->
        console.log "Error downloading from #{url} and saving to #{targetFile}: #{JSON.stringify(error)}"

  @downloadLanguageSoundFiles = ->
    filesToCopy = []
    dirsToCreate = []
    console.log JSON.stringify Papaya.config
    for language,data of Papaya.config.languages
      console.log "#{directoryPath}/#{language}"
      dirsToCreate.push "#{directoryPath}/#{language}"
      for phoneme in data.phonemes
        for voice in data.voices
          filesToCopy.push "#{language}/#{voice}_#{phoneme}.mp3"

    onDirsCreated = _.after dirsToCreate.length, ->
      console.log "Created #{JSON.stringify dirsToCreate} (unless they already existed)"

      onCopyComplete = _.after filesToCopy.length, ->
        console.log "Finished copying #{filesToCopy.length} files"

      fileTransfer = new FileTransfer()
      _.each filesToCopy, (file) ->
        source = "#{serverPath}/uploads/#{file}"
        #source = "file:///android_asset/www/#{file}"
        targetFile = "#{directoryPath}/#{file}"
        fileTransfer.download source, targetFile,
          (data) =>
            console.log "Copied #{file} to #{targetFile}"
            onCopyComplete()
          (error) -> console.log "Error downloading from #{source} and saving to #{targetFile}: #{JSON.stringify(error)}"

    for dir in dirsToCreate
      gapFile.mkDirectory "#{dir}"
      onDirsCreated()

  @deletePapayaAssetsIfExists = (options) ->
    # Delete any old files
    #
    #
    console.log "Looking for old Papaya files to delete"
    window.requestFileSystem LocalFileSystem.PERSISTENT, 0, (fileSystem) ->
      fileSystem.root.getDirectory appName, {
        create: false
        exclusive: false
      }
      , (directoryEntry) ->
          directoryEntry.removeRecursively ->
            console.log "Removed #{appName} directory and all it's contents"
            options.success?()
          , ->
            console.log "Failed to remove #{appName}"
            options.error?()
      , ->
        console.log "#{appName} directory does not exist"
        options.success?()
          

  @initializePhonegapFiles = ->

    #@deletePapayaAssetsIfExists
    #  success: ->

        configPath = "www/config/config.json"

        window.plugins.asset2sd.startActivity {
            asset_file: "www/config/config.json",
            destination_file_location: appName
            destination_file: "config.json"
          },
            () ->
              console.log "Successfully copied from #{configPath} to #{appName}. Waiting half a second before loading it."
              _.delay ->
                Papaya.loadConfig
                  error: (error) ->
                    console.log "Error loading config file after copying from assets: #{JSON.stringify error}"
                    throw
                      name:'LoadConfigError'
                      message:"Could not load config file: #{JSON.stringify error}"
                  success: ->


                    fileCount = 0
                    for language,data of Papaya.config.languages
                      for phoneme in data.phonemes
                        for voice in data.voices
                          fileCount += 1

                    reloadAfterAllFilesTransferred = _.after fileCount, -> document.location.reload()

                    for language,data of Papaya.config.languages
                      for phoneme in data.phonemes
                        for voice in data.voices
                          window.plugins.asset2sd.startActivity {
                              asset_file: "www/languages/#{language}/#{voice}_#{phoneme}.mp3"
                              destination_file_location: "#{appName}/#{language}"
                              destination_file: "#{voice}_#{phoneme}.mp3"
                            },
                              () ->
                                reloadAfterAllFilesTransferred()
                                console.log "Copied www/#{language}/#{voice}_#{phoneme}.mp3"
                                $("body").append "Copied www/#{language}/#{voice}_#{phoneme}.mp3"
                            ,
                              (error) -> console.log "ERROR: Could not copy www/#{language}/#{voice}_#{phoneme}.mp3: #{JSON.stringify error}"
              , 500
          ,
            () ->
              console.log "Failed to initialize config.json"

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
      heightMultiplier = .3
    else
      heightMultiplier = .3

    $('#createdWords').css
      width: $(window).width()-20
      height: $(window).height()*heightMultiplier

    $('#createdWords').html $('#createdWords').text()
    $('#createdWords').boxfit()

  @play = (filename,button) ->
    if Papaya.onPhonegap()
      Papaya.media?.release()
      button.addClass("playing")
      url = "#{directoryPath}/#{$("a.language.selected").text()}/#{filename}"
      console.log "Playing #{url}"
      Papaya.media = new Media url, ->
        button.removeClass("playing")
      Papaya.media.play()
    else
      $("#jplayer").jPlayer("setMedia",{mp3: "sounds/#{$("a.language.selected").text()}/#{filename}"})
      $("#jplayer").jPlayer("play")

  @record = ->
    $("#record-start-stop").addClass "recording"
    $("#record-start-stop").html "stop recording"
    Papaya.recorder.record()
    @autoStop = _.delay(@stop, Papaya.config.maxRecordTime)

  @stop = ->
    $("#record-start-stop").removeClass "recording"
    $("#record-start-stop").html "record my voice"
    Papaya.recorder.stop()
    clearTimeout(@autoStop)

class Router extends Backbone.Router
  routes:
    "": "default"
    "downloadLanguages": "downloadLanguages"
    "joinPhonemes": "joinPhonemes"
    "availablePhonemes": "availablePhonemes"
    "listenPhonemes": "listenPhonemes"
    "language/:language" : "changeLanguage"
    "selectLanguage" : "selectLanguage"

  downloadLanguages: () ->
    $("#downloadLanguages").show()
    $("#downloadLanguages").html "
      <div>
      Currently Loaded Languages:<br/>
      #{
        available_languages =_.keys Papaya.config.languages

        _.map(available_languages, (language) ->
            "#{language}"
        ).join("<br/>")
      }
      </div>
      <br/>
      <div>
        Languages available for update/download: <div id='languages_available_for_downloading'></div>
      </div>
      <button type='button' id='add_update_selected_languages'>Add/update selected languages</button>
    "
    $.ajax
      url: "#{serverPath}/languages"
      dataType: "json"
      error: (error) -> console.log JSON.stringify(error)
      success: (result) ->
        $('#languages_available_for_downloading').html "
            #{
              _.map(result, (language) -> "
                <label for='download-#{language}'>#{language}</label>
                <input id='download-#{language}' value='#{language}' class='check' type='checkbox' 
                  #{if _.contains(available_languages, language) then 'checked=\'true\'' else ''}></input><br/>
                "
              ).join("")
            }
        "


  updateLanguage: () ->
    Papaya.updatePhonemes()
    $(".phoneme-selector").hide()
    $(".created-words").hide()
    $("span.meta").hide()
    $(".listen-phonemes").hide()
    $("#recording-buttons").hide()
    $("#voice-selector").hide()

  changeLanguage: (language) ->
    $("a.language").removeClass "selected"
    $("##{language}").addClass "selected"
    $("a.language").not(".selected").hide()
    languageSettings = Papaya.config.languages[language]
    $('#availablePhonemes').val languageSettings.phonemes
    languageSettings.onLoad?()

    $("#voice-selector").html _.map(languageSettings.voices, (voice) ->
      "<span class='voice' id='voice-#{voice}'>#{voice}</span> "
    ).join("")
# Make first voice the default
    $($(".voice")[0]).addClass "selected"

    @updateLanguage()

  selectLanguage: ->
    $("a.language").not(".selected").show()

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
      filename = "#{$("#voice-selector span.selected").text()}_#{phoneme}.mp3"
      Papaya.play(filename,button)
      _.delay ->
        $("#listen-status").html ""
      , 1000

$("#voice-selector").on "click", "span", (event) ->
  $(event.target).siblings().removeClass "selected"
  $(event.target).addClass "selected"

$("#downloadLanguages").on "click", "#add_update_selected_languages", (event) ->
  Papaya.downloadLanguageJson _.pluck($(".check:checked"), "value"), ->
    Papaya.loadConfig
      error: (error) ->
        console.log "Error loading config file: #{error}"
      success: ->
        Papaya.downloadLanguageSoundFiles()
    

# Bootup activities

$(document).ready () ->
  $("#jplayer").jPlayer
    error: (error) ->
      if error.jPlayer.error.type is "e_url"
        phoneme = $("#listen-status").text()
        filename = "#{$("#voice-selector span.selected").text()}_#{phoneme}.mp3"
        $("#listen-status").append "<br><span style='font-size:20px'>No sound file available (#{filename})</span>"

Papaya.config = {}


Papaya.updateCreatedWordsDivSize()

window.addEventListener("resize", ->
  Papaya.updateCreatedWordsDivSize()
, false)

router = new Router()


if Papaya.onPhonegap()
  #$("[href=#downloadLanguages]").show()
  document.addEventListener("deviceready",
    ->
      #navigator.splashscreen.hide()
      Papaya.recorder = new RecordAudio()

      Papaya.loadConfig
        success: (success) ->
          Backbone.history.start()
          console.log "Loaded config."
        error: (error) ->
          console.log "Could not load config, initializing Phonegap files"
          $("body").html "<div id='phonemeSelector'>" + _.map("Preparing Papaya for it's first run...".split(""), (letter) ->
            if letter is " "
              "<br/>"
            else
              "<span style='width:20px;height:20px' class='phoneme-button button'>#{letter}</span>"
          ).join("") + "</div>"
          Papaya.initializePhonegapFiles()
    false
  )

else
  Papaya.loadConfig()
  Backbone.history.start()

  Papaya.recorder = new RecordAudio()
