# YouTube Transcript Downloader

A simple Python script to download transcripts from YouTube videos and playlists.

## Setup

1. Install required packages:
   ```
   pip install youtube-transcript-api requests
   ```

## Usage

### Download a single video transcript:
```
python3 yt-transcripts-download.py https://www.youtube.com/watch?v=VIDEO_ID
```

### Download a playlist's transcripts:
```
python3 yt-transcripts-download.py https://www.youtube.com/playlist?list=PLAYLIST_ID
```

### Download from list of URLs:
1. Create `video_urls.txt` with one URL per line (can be videos or playlists)
2. Run `python3 yt-transcripts-download.py`

### Combine multiple transcripts into one file:
```
python3 yt-transcripts-download.py --combine all_transcripts.txt
```

### All options:
```
python3 yt-transcripts-download.py [URL] [options]

Options:
  -i, --input FILE         Input file with YouTube URLs (default: video_urls.txt)
  -o, --output-dir DIR     Output directory for transcripts (default: transcripts)
  -c, --combine FILENAME   Combine all transcripts into a single file
```

Transcripts are saved in the `transcripts` folder with concise filenames formatted as `ChannelName-VideoTitle_VideoID.txt`. Channel names are limited to 20 characters and video titles to 40 characters, with spaces replaced by underscores. 