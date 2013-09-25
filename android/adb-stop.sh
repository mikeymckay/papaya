pkg=$(/mnt/spinner/adt-bundle-linux/sdk/platform-tools/aapt dump badging $1|awk -F" " '/package/ {print $2}'|awk -F"'" '/name=/ {print $2}')
act=$(/mnt/spinner/adt-bundle-linux/sdk/platform-tools/aapt dump badging $1|awk -F" " '/launchable-activity/ {print $2}'|awk -F"'" '/name=/ {print $2}')
  adb shell am force-stop -n $pkg/$act
