# Radio Buffer

Helps to prepare music for a walk or other offline activities.

## Configuration

Envs:

- `USER_AGENT` user agent to use when fetching data form stream, defaults to `RadioBuffer`
- `STREAM_URL`, eg. `http://your-music.radio:1234/stream`
- `REQUIRED_COLLECTED_MB` size after which collecting music will be paused
- `DATA_DIR` path where music will be stored, defaults to `/data`

All command options are passed to `streamripper` binary, run `glorpen/radiobuffer -help` for more info.

## How it works

### Https streams

Streamripper doesn't support connecting to HTTPS endpoints (https://sourceforge.net/p/streamripper/bugs/224/).
When https scheme is detected, a simple http proxy is spawned which then is used by Streamripper.

### Collecting music

When no `REQUIRED_COLLECTED_MB` is provided music will be collected until script is stopped.

### Making sure that music-to-go is always available

When `REQUIRED_COLLECTED_MB` is set to required size in MB, music collection will stop upon exceeding given limit.
Script will pause fetching new music until `DATA_DIR` will have some files moved from / deleted by eg. transferring
waiting music to listening device of your choosing.

Upon `DATA_DIR` shrinking bellow `REQUIRED_COLLECTED_MB` collection process will resume.
