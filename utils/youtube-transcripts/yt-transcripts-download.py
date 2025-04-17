from youtube_transcript_api import YouTubeTranscriptApi
from urllib.parse import urlparse, parse_qs
import os
import requests
import re
import sys
import time
import random
import argparse
from pathlib import Path

def get_video_id(url):
    """Extracts the YouTube video ID from URL."""
    parsed_url = urlparse(url.strip())
    if parsed_url.hostname in ['www.youtube.com', 'youtube.com']:
        if 'v' in parse_qs(parsed_url.query):
            return parse_qs(parsed_url.query)['v'][0]
        elif '/shorts/' in parsed_url.path:
            # Handle YouTube Shorts URLs
            return parsed_url.path.split('/shorts/')[1].split('/')[0]
    elif parsed_url.hostname in ['youtu.be']:
        return parsed_url.path[1:]
    else:
        raise ValueError(f"Unsupported URL format: {url}")

def is_playlist_url(url):
    """Checks if the URL is a YouTube playlist."""
    parsed_url = urlparse(url.strip())
    if parsed_url.hostname in ['www.youtube.com', 'youtube.com']:
        return 'list' in parse_qs(parsed_url.query)
    return False

def get_playlist_id(url):
    """Extracts the YouTube playlist ID from URL."""
    parsed_url = urlparse(url.strip())
    if parsed_url.hostname in ['www.youtube.com', 'youtube.com']:
        if 'list' in parse_qs(parsed_url.query):
            return parse_qs(parsed_url.query)['list'][0]
    raise ValueError(f"Not a valid playlist URL: {url}")

def get_videos_from_playlist(playlist_id):
    """Extracts video URLs from a YouTube playlist."""
    videos = []
    url = f"https://www.youtube.com/playlist?list={playlist_id}"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        # Use regex to find video IDs in the playlist page
        video_ids = re.findall(r'watch\?v=([^"&]+)', response.text)
        
        # Remove duplicates while preserving order
        unique_video_ids = []
        for video_id in video_ids:
            if video_id not in unique_video_ids:
                unique_video_ids.append(video_id)
        
        # Convert video IDs to video URLs
        videos = [f"https://www.youtube.com/watch?v={vid}" for vid in unique_video_ids]
        
        print(f"Found {len(videos)} videos in playlist {playlist_id}")
        return videos
    
    except Exception as e:
        print(f"Failed to get videos from playlist {playlist_id}: {e}")
        return []

def get_video_title(video_id):
    """Fetches the title of a YouTube video using its video ID."""
    try:
        response = requests.get(f"https://www.youtube.com/watch?v={video_id}")
        response.raise_for_status()
        
        # Extract title from HTML using regex
        title_match = re.search(r'<title>(.*?)</title>', response.text)
        if title_match:
            title = title_match.group(1)
            # Remove " - YouTube" suffix if present
            if title.endswith(" - YouTube"):
                title = title[:-10]
            return title
        
        return video_id  # Fallback to video_id if title extraction fails
    except Exception as e:
        print(f"Could not fetch title for video {video_id}: {e}")
        return video_id  # Fallback to video_id

def get_channel_name(video_id):
    """Fetches the channel name for a YouTube video."""
    try:
        response = requests.get(f"https://www.youtube.com/watch?v={video_id}")
        response.raise_for_status()
        
        # Try to extract channel name using regex
        # First look for the standard pattern
        channel_match = re.search(r'"channelName":"([^"]+)"', response.text)
        
        # If not found, try alternative pattern
        if not channel_match:
            channel_match = re.search(r'"ownerChannelName":"([^"]+)"', response.text)
            
        if channel_match:
            return channel_match.group(1)
        
        # Fallback to a more general pattern if needed
        channel_match = re.search(r'<link rel="canonical" href="https://www\.youtube\.com/channel/([^"]+)"', response.text)
        if channel_match:
            return channel_match.group(1)
            
        return "Unknown_Channel"  # Fallback
    except Exception as e:
        print(f"Could not fetch channel name for video {video_id}: {e}")
        return "Unknown_Channel"  # Fallback

def sanitize_filename(text):
    """Sanitize text for use in filenames:
    - Remove invalid characters and all punctuation
    - Replace spaces with underscores
    """
    # First, remove any characters not allowed in filenames and all punctuation
    sanitized = re.sub(r'[^\w\s]', '', text)
    
    # Replace spaces with underscores
    sanitized = re.sub(r'\s+', '_', sanitized)
    
    # Trim to reasonable length (caller will decide whether to use short or long version)
    return sanitized.strip()

def download_transcript(url, output_dir, combined_file=None):
    """Downloads transcript for a single YouTube video URL."""
    try:
        video_id = get_video_id(url)
        print(f"Processing video {video_id}...")
        
        # Get video title
        video_title = get_video_title(video_id)
        print(f"Title: {video_title}")
        
        # Get channel name
        channel_name = get_channel_name(video_id)
        print(f"Channel: {channel_name}")
        
        # Create sanitized filename components with length limits
        safe_title = sanitize_filename(video_title)[:40]
        safe_channel = sanitize_filename(channel_name)[:20]
        
        # Include channel name in filename
        filename = f"{safe_channel}-{safe_title}_{video_id}.txt"
        
        output_path = output_dir / filename
        if os.path.exists(output_path) and combined_file is None:
            print(f"Transcript for '{video_title}' already exists. Skipping download.")
            return
        
        print(f"Downloading transcript...")
        transcript = YouTubeTranscriptApi.get_transcript(video_id)
        full_text = ' '.join(segment['text'] for segment in transcript)

        # If we're combining transcripts into one file
        if combined_file is not None:
            with open(combined_file, 'a', encoding='utf-8') as outfile:
                outfile.write(f"\n\n{'='*80}\n")
                outfile.write(f"Channel: {channel_name}\n")
                outfile.write(f"Title: {video_title}\n")
                outfile.write(f"Source URL: {url}\n")
                outfile.write(f"{'='*80}\n\n")
                outfile.write(full_text)
            print(f"Transcript appended to {combined_file}")
        else:
            # Normal mode - save individual files
            with open(output_path, 'w', encoding='utf-8') as outfile:
                outfile.write(f"Channel: {channel_name}\n")
                outfile.write(f"Title: {video_title}\n")
                outfile.write(f"Source URL: {url}\n\n")
                outfile.write(full_text)
            print(f"Transcript saved to {output_path}")
        
    except Exception as e:
        print(f"Failed to get transcript for {url}: {e}")

def download_transcripts(input_file='video_urls.txt', output_dir='transcripts', combined_output=None):
    """Downloads transcripts from YouTube URLs listed in input_file."""
    # Get the directory where the script is located
    script_dir = Path(os.path.dirname(os.path.abspath(__file__)))
    
    # Create output directory relative to script location
    output_path = script_dir / output_dir
    output_path.mkdir(exist_ok=True)
    
    # If input file is a relative path, make it relative to script location
    if not os.path.isabs(input_file):
        input_file = script_dir / input_file

    # If using combined output, create/clear the file
    if combined_output is not None:
        combined_file_path = output_path / combined_output
        with open(combined_file_path, 'w', encoding='utf-8') as f:
            f.write(f"COMBINED YOUTUBE TRANSCRIPTS\n{'='*80}\n\n")
    else:
        combined_file_path = None

    # Process command line URL argument if provided
    if len(sys.argv) > 1 and sys.argv[1].startswith("http"):
        url = sys.argv[1]
        if is_playlist_url(url):
            playlist_id = get_playlist_id(url)
            videos = get_videos_from_playlist(playlist_id)
            for i, video_url in enumerate(videos):
                download_transcript(video_url, output_path, combined_file_path)
                if i < len(videos) - 1:  # If not the last video
                    delay = random.uniform(1.5, 3.5)
                    print(f"Waiting {delay:.2f} seconds before processing next video...")
                    time.sleep(delay)
        else:
            download_transcript(url, output_path, combined_file_path)
        return

    # Process URLs from input file
    with open(input_file, 'r', encoding='utf-8') as f:
        urls = [line.strip() for line in f if line.strip()]

    for i, url in enumerate(urls):
        if is_playlist_url(url):
            playlist_id = get_playlist_id(url)
            videos = get_videos_from_playlist(playlist_id)
            for j, video_url in enumerate(videos):
                download_transcript(video_url, output_path, combined_file_path)
                if j < len(videos) - 1:  # If not the last video in playlist
                    delay = random.uniform(1.5, 3.5)
                    print(f"Waiting {delay:.2f} seconds before processing next video...")
                    time.sleep(delay)
        else:
            download_transcript(url, output_path, combined_file_path)
        
        # Add delay between URLs in the input file (if not the last URL)
        if i < len(urls) - 1:
            delay = random.uniform(2.0, 4.0)
            print(f"Waiting {delay:.2f} seconds before processing next URL...")
            time.sleep(delay)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download YouTube video transcripts")
    parser.add_argument("url", nargs="?", help="YouTube video or playlist URL (optional)")
    parser.add_argument("-i", "--input", default="video_urls.txt", 
                      help="Input file with YouTube URLs (default: video_urls.txt)")
    parser.add_argument("-o", "--output-dir", default="transcripts", 
                      help="Output directory for transcripts (default: transcripts)")
    parser.add_argument("-c", "--combine", metavar="FILENAME", 
                      help="Combine all transcripts into a single file with the specified name")
    
    args = parser.parse_args()
    
    # If URL is provided as positional arg, replace sys.argv[1] to maintain compatibility
    if args.url and len(sys.argv) > 1:
        sys.argv[1] = args.url
    
    download_transcripts(
        input_file=args.input, 
        output_dir=args.output_dir,
        combined_output=args.combine
    )
