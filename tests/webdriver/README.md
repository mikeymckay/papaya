Run these tests by:

Installing required node packages:

$> sudo npm install

Then execute the tests:

$> coffee test.coffee

To make them work against a local selenium instance controlling Chrome:

1) Install the standalone Selenium server

(from: http://www.danstraw.com/installing-selenium-server-2-as-a-service-on-ubuntu/2010/09/23/)

First, browse to http://code.google.com/p/selenium/downloads/list click on selenium-server-standlone-2.*.jar link, and then copy the url of the selenium-server-standlone-2.*.jar file.

Next, open up a terminal window and type:

sudo su
mkdir /usr/lib/selenium/
cd /usr/lib/selenium/
wget url-you-copied-above
mkdir -p /var/log/selenium/
chmod a+w /var/log/selenium/


2) Add the selenium driver:

Get it from here:

http://code.google.com/p/chromedriver/downloads/list

Put it in /usr/local/bin

3) Get it all working with selenium

Save the following as /etc/init.d/selenium :

#!/bin/bash

    case "${1:-''}" in
            'start')
                    if test -f /tmp/selenium.pid
                    then
                            echo "Selenium is already running."
                    else
#                        java -jar /usr/lib/selenium/selenium-server-standalone-2.26.0.jar -port 4443 > /var/log/selenium/selenium-output.log 2> /var/log/selenium/selenium-error.log & echo $! > /tmp/selenium.pid
                            java -jar /usr/lib/selenium/selenium-server-standalone-2.26.0.jar -Dwebdriver.chrome.driver="/usr/local/bin/chromedriver" -port 4443 > /var/log/selenium/selenium-output.log 2> /var/log/selenium/selenium-error.log & echo $! > /tmp/selenium.pid
                            echo "Starting Selenium..."

                            error=$?
                            if test $error -gt 0
                            then
                                    echo "${bon}Error $error! Couldn't start Selenium!${boff}"
                            fi
                    fi
            ;;
            'stop')
                    if test -f /tmp/selenium.pid
                    then
                            echo "Stopping Selenium..."
                            PID=`cat /tmp/selenium.pid`
                            kill -3 $PID
                            if kill -9 $PID ;
                                    then
                                            sleep 2
                                            test -f /tmp/selenium.pid && rm -f /tmp/selenium.pid
                                    else
                                            echo "Selenium could not be stopped..."
                                    fi
                    else
                            echo "Selenium is not running."
                    fi
                    ;;
            'restart')
                    if test -f /tmp/selenium.pid
                    then
                            kill -HUP `cat /tmp/selenium.pid`
                            test -f /tmp/selenium.pid && rm -f /tmp/selenium.pid
                            sleep 1
#                        java -jar /usr/lib/selenium/selenium-server-standalone-2.26.0.jar -port 4443 > /var/log/selenium/selenium-output.log 2> /var/log/selenium/selenium-error.log & echo $! > /tmp/selenium.pid
                            java -jar /usr/lib/selenium/selenium-server-standalone-2.26.0.jar -Dwebdriver.chrome.driver="/usr/local/bin/chromedriver" -port 4443 > /var/log/selenium/selenium-output.log 2> /var/log/selenium/selenium-error.log & echo $! > /tmp/selenium.pid
                            echo "Reload Selenium..."
                    else
                            echo "Selenium isn't running..."
                    fi
                    ;;
            *)      # no parameter specified
                    echo "Usage: $SELF start|stop|restart|reload|force-reload|status"
                    exit 1
            ;;
    esac

------------

Make it executable:

chmod 755 /etc/init.d/selenium

Start it up:

/etc/init.d/selenium start

Now your tests need to include:

browser = webdriver.remote(
  "127.0.0.1"
  , 4443
)

browser.init browserName: "chrome"
