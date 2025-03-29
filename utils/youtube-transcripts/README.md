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

Transcripts are saved in the `transcripts` folder with concise filenames formatted as `ChannelName-VideoTitle_VideoID.txt`. Channel names are limited to 10 characters and video titles to 20 characters, with spaces replaced by underscores. 