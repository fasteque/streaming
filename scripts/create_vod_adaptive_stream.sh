#!/usr/bin/env bash

set -e

# Usage create_vod_adaptive_stream.sh SOURCE_FILE [OUTPUT_NAME]
[[ ! "${1}" ]] && echo "Usage: create_vod_adaptive_stream.sh SOURCE_FILE" && exit 1 

bitrate_renditions=(
#720p
"6500k"
#1080p
"10000k"
#1440p
"14000k"
#2160p
"20000k"
)

audiorate_renditions=(
#720p
"128k"
#1080p
"128k"
#1440p
"192k"
#2160p
"192k"
)

format_to_convert=(
"matroska,webm"
)

max_bitrate_ratio=1.07          # Maximum accepted bitrate fluctuations.
rate_monitor_buffer_ratio=1.5   # Maximum buffer size between bitrate conformance checks.
max_supported_bitrate=25000

#########################################################################

source="${1}"
# Leave only last component of path.
target="${source##*/}"
# Strip extension.
target="${target%.*}"

# Get FORMAT info.
eval $(ffprobe -v error -show_entries format=bit_rate,size,duration,filename,format_name -of default=noprint_wrappers=1 ${source})
if [[ ${bit_rate} =~ [^[:digit:]] ]]
then
    format_bit_rate_kbps=-1
else
    format_bit_rate_kbps=$((${bit_rate}/1000))
fi
format_size=${size}
format_duration=${duration}
format_filename=${filename}
format_format_name=${format_name}
echo -e "\n------- FILE FORMAT -------"
echo -e "File: ${format_filename}"
echo -e "Bitrate (kbps): ${format_bit_rate_kbps}"
echo -e "Size (bytes): ${format_size}"
echo -e "Duration (seconds): ${format_duration}"
echo -e "Format: ${format_format_name}"
echo -e "---------------------"

# Get VIDEO stream info.
eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=width,height,codec_name,avg_frame_rate,bit_rate -of default=noprint_wrappers=1 ${source});
video_width=${width};
video_height=${height};
video_codec_name=${codec_name};
if [[ ${bit_rate} =~ [^[:digit:]] ]]
then
    video_bitrate=-1
else
    video_bitrate=$((${bit_rate}/1000))
fi
echo -e "\n------- VIDEO STREAM 0 -------"
echo -e "Width: ${video_width}"
echo -e "Height: ${video_height}"
echo -e "Codec: ${video_codec_name}"
echo -e "Bitrate (kbps): ${video_bitrate}"
echo -e "---------------------"

# Get AUDIO stream info.
eval $(ffprobe -loglevel error -select_streams a:0 -show_entries stream=codec_name,sample_rate,bit_rate -of default=noprint_wrappers=1 ${source});
audio_codec_name=${codec_name}
audio_sample_rate=${sample_rate}
audio_bit_rate=${bit_rate}
echo -e "\n------- AUDIO STREAM 0 -------"
echo -e "Codec: ${audio_codec_name}"
echo -e "Sample rate (Hz): ${audio_sample_rate}"
echo -e "Bitrate (kbps): ${audio_bit_rate}"
echo -e "---------------------\n"

encoding_required=false

# 0: transcoding not required
# 1: bitrate too high
# 2: video codec not supported
# 3: audio codec not supported

# Filter out videos for which original file can used for playback.
echo "Checking format and video stream 0 bitrate..."
if [ "$format_bit_rate_kbps" -ge "$max_supported_bitrate" ]; then
	echo "Bitrate too high, re-encoding required"
	encoding_required=true
else
	if [ "$video_bitrate" -ge "$max_supported_bitrate" ]; then
		echo "Bitrate too high, re-encoding required"
		encoding_required=true
	else
		echo "No need to change bitrate"
	fi
fi

# FIXME: implement smart and selective encoding options.
for i in "${format_to_convert[@]}"
do
    if [ "$i" == "${format_format_name}" ] ; then
        echo "Found format to convert: ${i}"
        encoding_required=true
    fi
done

# FIXME: implement smart and selective encoding options.


if [ "$encoding_required" = true ] ; then
    echo "Setting encoding parameters"
    
	# Static parameters.
	static_params="-c:a aac -ar 48000 -c:v h264 -profile:v main -crf 20 -sc_threshold 0"
	
	# Misc parameters.
	misc_params="-hide_banner -y"
	
	cmd=""	

	# FIXME: if the original bitrate is less or equal, probably it's better to use that value.
	if [ "$video_height" -gt 1440 ]; then
		bitrate=${bitrate_renditions[3]}
		audiorate=${audiorate_renditions[3]}
	else
		if [ "$video_height" -gt 1080 ]; then
			bitrate=${bitrate_renditions[2]}
			audiorate=${audiorate_renditions[2]}
		else
			if [ "$video_height" -gt 720 ]; then
				bitrate=${bitrate_renditions[1]}
				audiorate=${audiorate_renditions[1]}
			else
				bitrate=${bitrate_renditions[0]}
				audiorate=${audiorate_renditions[0]}
			fi		
		fi
	fi
	
	maxrate="$(echo "`echo ${bitrate} | grep -oE '[[:digit:]]+'`*${max_bitrate_ratio}" | bc)"
  	bufsize="$(echo "`echo ${bitrate} | grep -oE '[[:digit:]]+'`*${rate_monitor_buffer_ratio}" | bc)"
	
	cmd+=" ${static_params}"
	cmd+=" -b:v ${bitrate} -maxrate ${maxrate%.*}k -bufsize ${bufsize%.*}k -b:a ${audiorate}"
	
	cmd+=" NEW_${target}.mp4"
	
	# Start conversion.
	echo -e "Executing command:\nffmpeg ${misc_params} -i ${source} ${cmd}"
	ffmpeg ${misc_params} -i ${source} ${cmd}
	
	echo "Done"
fi
