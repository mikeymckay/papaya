This app is targeted for building letter flashcards and practicing sounds.

How this is organized:

html is where we find all html/javascript/css

android is used for compiling the html into a native app

For testing you can just use a local webserver to serve the html. I like python's

      python -m SimpleHTTPServer


Uses flash or phonegap for playback/recording when necessary

Tutorial used for setting up phonegap
http://agiliq.com/blog/2012/03/developing-android-applications-from-command-line/

Once above is done you compile with:

      ant clean debug install
