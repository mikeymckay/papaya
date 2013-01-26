#webdriver = require("wd-zombie")
webdriver = require("wd")
assert = require("assert")

#browser = webdriver.remote()
browser = webdriver.remote(
  "127.0.0.1"
  , 4443
)

wait = (seconds, browser, callback) ->
  setTimeout(callback, seconds*1000)

isTextShown = (textToLookFor, browser, callback) ->
  browser.elementByTagName "body", (err,element) ->
    if err?
      console.log err
      return
    element.textPresent textToLookFor, (error, textPresent) ->
      assert.ok textPresent, "'#{textToLookFor}' was not found"
      callback()

isTextNotShown = (textToLookFor, browser, callback) ->
  browser.elementByTagName "body", (err,element) ->
    if err?
      console.log err
      return
    element.textPresent textToLookFor, (error, textPresent) ->
      assert.ok not textPresent, "'#{textToLookFor}' was found"
      callback()

fillElementByCss = (css,text,browser,callback) ->
  browser.elementByCss css, (err,element) ->
    if err?
      console.log err
      return
    browser.type element,text, ->
      callback()

clickElementByCSSWithText = (css,text,browser,callback) ->
  browser.eval "$('#{css}:contains(#{text})')", (err,element) ->
    if err? or element.length is 0
      console.log "Error clicking: $('#{css}:contains(#{text})')"
      console.log err
      return
    browser.eval "$('#{css}:contains(#{text})')[0].click()", ->
      callback()

clickElementByCss = (css,browser,callback) ->
  browser.elementByCssSelector css, (err,element) ->
    if err?
      console.log "Error clicking on #{css} + #{err}"
      console.log err
      return
    browser.clickElement element, ->
      callback()

dumpSource = (browser, callback) ->
  browser.eval "document.getElementsByTagName('html')[0].innerHTML", (err,result) ->
    console.log result
    callback()

loginAsAdmin = (browser, callback) ->
  isTextShown "Enumerator", browser, ->
    fillElementByCss "#login_username","admin", browser, ->
      fillElementByCss "#login_password",passwords["admin"], browser, ->
        clickElementByCss "button.login", browser, ->
          browser.waitForElementByCssSelector "h1", "1000", ->
            isTextShown "Assessments", browser, ->
              callback()

passwords = require('./passwords.json')

#browser.init browserName: "zombie", ->
browser.init browserName: "chrome", ->
  browser.get "http://localhost:8000/papaya/html", ->
    clickElementByCSSWithText "a","Join Letters", browser, ->
      isTextShown "space", browser, ->
        isTextShown "dh", browser, ->
          clickElementByCSSWithText "a","Listen to Letter Sounds", browser, ->
            isTextShown "Child", browser, ->
              isTextShown "Female", browser, ->
                isTextShown "Male", browser, ->
                  clickElementByCSSWithText "a","English", browser, ->
                    isTextNotShown "Female", browser, ->
                      clickElementByCSSWithText "a","Listen to Letter Sounds", browser, ->
                        isTextNotShown "Child", browser, ->
                          clickElementByCSSWithText "a","Join Letters", browser, ->
                            isTextNotShown "dh", browser, ->
                              clickElementByCSSWithText "a","Listen to Letter Sounds", browser, ->
                                clickElementByCSSWithText "span","record my voice", browser, ->
                                  isTextShown "stop recording", browser, ->
                                    wait 5,browser, ->
                                      isTextNotShown "stop recording", browser, ->
                                        isTextShown "record my voice", browser, ->

