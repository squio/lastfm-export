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
    local lastFile=$(cd "$EXPORT_DIR" && ls | grep '.json' | sort | tail -n 1)
    if [ -z "$lastFile" ]; then
        echo 0
        return
    fi
    # Get the timestamp of the first non-null track in the last file
    echo $(jq -r ".recenttracks.track[].date.uts" "$EXPORT_DIR/$lastFile" | grep -v null | head -n 1)
}

FROM_TS=$(($(get_last_timestamp)+1))
echo "Resuming from timestamp: $FROM_TS"
if [[ "$FROM_TS" -eq 1 ]]; then
    echo "Starting from the beginning"
    read -p "Continue? (y/n) " confirm
    if [[ "$confirm" != "y" ]]; then
        exit 0
    fi
fi

START_PAGE=1
while true; do
    URL="ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&api_key=$API_KEY&user=$USER_NAME&format=json&limit=1000&extended=1&page=$START_PAGE&from=$FROM_TS"
    echo "Fetching page $START_PAGE"
    curl $URL --silent | jq . > "$TMPFILE"
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
