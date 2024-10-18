#!/bin/sh
# vim:sw=4:ts=4:et

set -e

FILES=$(find /usr/share/nginx/html -type f -exec grep -q "https://oss-collab.excalidraw.com" {} \; -print)

#APP_WS_OLD_SERVER_URL="https://oss-collab.excalidraw.com"
#APP_WS_NEW_SERVER_URL="http://localhost:3002"

for FILE in $FILES
do
  ABS_FILE=$(realpath $FILE)
	echo "Processing $ABS_FILE"
	sed 's#'"$APP_WS_OLD_SERVER_URL"'#'"$APP_WS_NEW_SERVER_URL"'#g' -i "$ABS_FILE"
done
