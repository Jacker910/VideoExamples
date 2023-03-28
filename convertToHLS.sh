#!/bin/bash

# Specify the path of the folder containing the MP4 videos
VIDEO_FOLDER="./Video"

# Specify the path of the folder to save the HLS files
HLS_FOLDER="./HLS"

# Specify the list of bitrates and resolutions for the different HLS variants
BITRATES=("300000" "600000" "1200000" "2500000")
RESOLUTIONS=("240x426" "360x640" "480x854" "720x1280")

# Create the HLS folder if it doesn't exist
mkdir -p "${HLS_FOLDER}"

# Loop through all the MP4 videos in the folder and convert them to adaptive HLS
for video in "${VIDEO_FOLDER}"/*.mp4; do
  filename=$(basename -- "${video}")
  extension="${filename##*.}"
  filename="${filename%.*}"

  # Create a new subdirectory for the video in the HLS folder
  video_folder="${HLS_FOLDER}/${filename}"
  mkdir -p "${video_folder}"

  # Loop through the list of bitrates and resolutions and create a new variant for each combination
  for i in "${!BITRATES[@]}"; do
    bitrate="${BITRATES[$i]}"
    resolution="${RESOLUTIONS[$i]}"
    output_file="${filename}_${bitrate}_${resolution}.m3u8"
    ffmpeg -i "${video}" -c:v libx264 -b:v "${bitrate}" -s "${resolution}" -profile:v main -level 3.0 -preset medium -g 60 -hls_init_time 0.1 -hls_time 0.2 -hls_list_size 0 -hls_segment_filename "${video_folder}/${filename}_${bitrate}_${resolution}_%03d.ts" "${video_folder}/${output_file}"
    echo "Converted ${filename}.${extension} to adaptive HLS variant with bitrate ${bitrate} and resolution ${resolution}"
  done

  # Create a master playlist for the video that lists the URLs of the HLS variant playlists
  playlist_file="${HLS_FOLDER}/${filename}/${filename}.m3u8"
  echo "#EXTM3U" > "${playlist_file}"
  for i in "${!BITRATES[@]}"; do
    bitrate="${BITRATES[$i]}"
    resolution="${RESOLUTIONS[$i]}"
    variant_file="${filename}_${bitrate}_${resolution}.m3u8"
    variant_url="${variant_file}"
    echo "#EXT-X-STREAM-INF:BANDWIDTH=${bitrate},CODECS=\"mp4a.40.2,avc1.4d001e\"" >> "${playlist_file}"
    echo "${variant_url}" >> "${playlist_file}"
  done
  echo "Created master playlist ${playlist_file}"
done
