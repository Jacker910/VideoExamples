#!/bin/bash

# Specify the path of the folder containing the MP4 videos
VIDEO_FOLDER="./Video"

# Specify the path of the folder to save the HLS files
HLS_FOLDER="./HLS"

# Create the HLS folder if it doesn't exist
mkdir -p "${HLS_FOLDER}"

# Loop through all the MP4 videos in the folder and convert them to HLS
for video in "${VIDEO_FOLDER}"/*.mp4; do
  filename=$(basename -- "${video}")
  extension="${filename##*.}"
  filename="${filename%.*}"

  # Create a new folder for the HLS files
  output_folder="${HLS_FOLDER}/${filename}_hls"
  mkdir -p "${output_folder}"

  # Convert the MP4 video to HLS using FFmpeg
  ffmpeg -i "${video}" -c:v libx264 -hls_time 10 -hls_list_size 0 -hls_segment_filename "${output_folder}/${filename}_%03d.ts" "${output_folder}/${filename}.m3u8"

  echo "Converted ${filename}.${extension} to HLS"
done
