set -eux
TIMESTAMP=""

TARGET="sweetmusic-vol5"

curl -X POST -f -H "Authorization: Bearer ${DROPBOX_TOKEN}" \
	-D - -H "Dropbox-API-Arg: {\"path\": \"/${TARGET}.pdf\",\"mode\": \"overwrite\",\"mute\": false}" -H "Content-Type: application/octet-stream" --data-binary @target/${TARGET}.pdf https://content.dropboxapi.com/2/files/upload
curl -X POST -f -H "Authorization: Bearer ${DROPBOX_TOKEN}" \
	-D - -H "Dropbox-API-Arg: {\"path\": \"/${TARGET}.epub\",\"mode\": \"overwrite\",\"mute\": false}" -H "Content-Type: application/octet-stream" --data-binary @target/${TARGET}.epub https://content.dropboxapi.com/2/files/upload
curl -X POST -f -H "Authorization: Bearer ${DROPBOX_TOKEN}" \
	-D - -H "Dropbox-API-Arg: {\"path\": \"/${TARGET}.txt\",\"mode\": \"overwrite\",\"mute\": false}" -H "Content-Type: application/octet-stream" --data-binary @target/${TARGET}.text https://content.dropboxapi.com/2/files/upload
