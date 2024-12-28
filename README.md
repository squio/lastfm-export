# lastfm-export.sh

A very basic script to download all "scrobbled" tracks for a user from <https://last.fm>

There are already a lot of scripts and tools to do the same, but these are either
web based tools (which I feel a bit uncomfortable to interact with) or they are much
more complicated, require lats of dependencies or simply didn't work out of the box.

I wanted to create a oneliner in simple shell script because the required API call is
really very simple.

Ultimately it became a bit more complicated because there is no option to order the results
so we can't use pagination to fetch the most recent results.
The solution is still pretty simple: save files with the most recent scrobble timestamp as
file name, use most recent timestamp + 1 second to resume from and that's it.

## Requirements

- `zsh` - this is the default on Mac OS (maybe bash will work, too lazy to test)
- `curl` - for making the API requests (default available on Mac OS)
- `jq` - for processing the downloaded JSON data (`brew install jq`)

## Setup

1. get a Last.FM API key <https://www.last.fm/api/account/create>
2. edit `example.env` to set your API key and last.fm user name
3. save as `.env` and run the script

When running the script at a later date, the timestamp of the last scrobbled track
is used to resume from.
