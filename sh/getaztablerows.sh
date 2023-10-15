#!/bin/sh

#call: ./getaztablerows.sh "storageaccountname" "tablename" <STORAGE_ACCOUN_KEY>

STORAGE_ACCOUNT=$1
TABLE_NAME=$2
STORAGE_KEY=$3

DATE_ISO=$(TZ=GMT date "+%a, %d %h %Y %H:%M:%S %Z")

URL_RESOURCE="/$STORAGE_ACCOUNT/$TABLE_NAME()"
STRING2SIGN="GET\n\n\n$DATE_ISO\n$URL_RESOURCE"
DECODED_KEY="$(echo -n $STORAGE_KEY | base64 -d -w0 | xxd -p -c256)"
SIGN=$(printf "$STRING2SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$DECODED_KEY" -binary |  base64 -w0)

curl -X GET \
  -H "x-ms-version:2023-01-03" \
  -H "x-ms-date:$DATE_ISO" \
  -H "Authorization: SharedKey $STORAGE_ACCOUNT:$SIGN" \
  "https://$STORAGE_ACCOUNT.table.core.windows.net/$TABLE_NAME()"