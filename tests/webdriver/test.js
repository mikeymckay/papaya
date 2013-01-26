// Generated by CoffeeScript 1.4.0
(function() {
  var assert, browser, clickCSSElementWithText, clickElementByCss, dumpSource, fillElementByCss, isTextShown, loginAsAdmin, passwords, webdriver;

  webdriver = require("wd");

  assert = require("assert");

  browser = webdriver.remote();

  browser = webdriver.remote("127.0.0.1", 4443);

  browser["foo"] = function() {
    return console.log("bar");
  };

  isTextShown = function(textToLookFor, browser, callback) {
    return browser.elementByTagName("body", function(err, element) {
      if (err != null) {
        console.log(err);
        return;
      }
      return element.textPresent(textToLookFor, function(error, textPresent) {
        assert.ok(textPresent, "'" + textToLookFor + "' was not found");
        return callback();
      });
    });
  };

  fillElementByCss = function(css, text, browser, callback) {
    return browser.elementByCss(css, function(err, element) {
      if (err != null) {
        console.log(err);
        return;
      }
      return browser.type(element, text, function() {
        return callback();
      });
    });
  };

  clickCSSElementWithText = function(css, text, browser, callback) {
    browser["eval"]("$('" + css + ":contains(" + text + ")').click()");
    return browser;
  };

  clickElementByCss = function(css, browser, callback) {
    return browser.elementByCssSelector(css, function(err, element) {
      if (err != null) {
        console.log("Error clicking on " + css + " + " + err);
        console.log(err);
        return;
      }
      return browser.clickElement(element, function() {
        return callback();
      });
    });
  };

  dumpSource = function(browser, callback) {
    return browser["eval"]("document.getElementsByTagName('html')[0].innerHTML", function(err, result) {
      console.log(result);
      return callback();
    });
  };

  loginAsAdmin = function(browser, callback) {
    return isTextShown("Enumerator", browser, function() {
      return fillElementByCss("#login_username", "admin", browser, function() {
        return fillElementByCss("#login_password", passwords["admin"], browser, function() {
          return clickElementByCss("button.login", browser, function() {
            return browser.waitForElementByCssSelector("h1", "1000", function() {
              return isTextShown("Assessments", browser, function() {
                return callback();
              });
            });
          });
        });
      });
    });
  };

  passwords = require('./passwords.json');

  browser.foo();

  browser.chain().init({
    browserName: "chrome"
  }).get("http://localhost:8000/papaya/html");

}).call(this);
