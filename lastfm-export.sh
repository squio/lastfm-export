#!/bin/zsh

SCRIPT_DIR=$(dirname $0)
source "$SCRIPT_DIR/.env"
if [[ -z "$API_KEY" || -z "$USER_NAME" ]]; then
    echo "API_KEY and USER_NAME must be set in .env file"
    exit 1
fi
EXPORT_DIR="$SCRIPT_DIR/export/$USER_NAME"
TMPFILE="$EXPORT_DIR/tmp.json"

mkdir -p "$EXPORT_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to create export directory"
    exit 1
fi


get_last_timestamp() {
    local lastFile=$(cd "$EXPORT_DIR" && ls | sort | tail -n1)
    if [ -z "$lastFile" ]; then
        echo 0
        return
    fi
    echo $(jq -r ".recenttracks.track[0].date.uts" "$EXPORT_DIR/$lastFile")
}

FROM_TS=$(($(get_last_timestamp)+1))
echo "Resuming from timestamp: $FROM_TS"

START_PAGE=1
while true; do
    URL="ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=$API_KEY&user=$USER_NAME&format=json&limit=1000&extended=1&page=$START_PAGE&from=$FROM_TS"
    echo "Fetching page $START_PAGE"
    curl $URL | jq . > "$TMPFILE"
    if [ $? -ne 0 ]; then
        echo "Failed to fetch page $START_PAGE"
        rm -f "$TMPFILE"
        break
    fi
    TIMESTAMP=$(jq -r ".recenttracks.track[-1].date.uts" "$TMPFILE")
    FILENAME="$EXPORT_DIR/$TIMESTAMP.json"
    mv "$TMPFILE" "$FILENAME"
    # use jq to check if totalPages is equal or greater than START_PAGE
    totalPages=$(jq -r '.recenttracks["@attr"].totalPages' "$FILENAME")
    if [ "$START_PAGE" -ge "$totalPages" ]; then
        echo "All pages fetched."
        break
    fi
    sleep 1
    START_PAGE=$((START_PAGE+1))
done
