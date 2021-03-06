#!/usr/bin/env bash
set -e

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
NC='\033[0m' # No Color

function print_usage() {
	echo "Usage: $0 [options] <source>"
	echo "	<source>    The video file to probe and re-encode."
	echo "Options:"
	echo "	-m          Dry run."
	echo "Example: $0 /path/to/video_file"
}

function echo_file_info() {
	echo -e "${green}[FILE]   $1${NC}"
}

function echo_info() {
	echo -e "${blue}[INFO]   $1${NC}"
}

function echo_warn() {
	echo -e "${yellow}[WARN]   $1${NC}"
}

function echo_error() {
	echo -e "${red}[ERR!]   $1${NC}"
}

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

# Formats supported natively by myCloud video players.
supported_video_formats="mov,mp4,m4a,3gp,3g2,mj2"
supported_video_codec="h264"
supported_audio_codec="aac"

max_bitrate_ratio=1.07          # Maximum accepted bitrate fluctuations.
rate_monitor_buffer_ratio=1.5   # Maximum buffer size between bitrate conformance checks.
max_supported_bitrate=25000

dry_run=false
# Read options
while getopts ":m" opt; do
	case $opt in
		m)
			dry_run=true
			;;
		\?)
			echo_error "Invalid option!" >&2
			print_usage
			exit 1
			;;
		:)
		print_usage
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))

# Check that the number of arguments is correct.
if [ $# != 1 ]; then
	print_usage
	exit 1
fi


source="${1}"
# Leave only last component of path.
target="${source##*/}"
# Strip extension.
target="${target%.*}"
extension="${source##*.}"
echo_info "File extension: ${extension}"

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
echo_file_info "------- FILE FORMAT -------"
echo_file_info "File: ${format_filename}"
echo_file_info "Bitrate (kbps): ${format_bit_rate_kbps}"
echo_file_info "Size (bytes): ${format_size}"
echo_file_info "Duration (seconds): ${format_duration}"
echo_file_info "Format: ${format_format_name}"
echo_file_info "---------------------"

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
echo_file_info "------- VIDEO STREAM 0 -------"
echo_file_info "Width: ${video_width}"
echo_file_info "Height: ${video_height}"
echo_file_info "Codec: ${video_codec_name}"
echo_file_info "Bitrate (kbps): ${video_bitrate}"
echo_file_info "---------------------"

# Get AUDIO stream info.
eval $(ffprobe -loglevel error -select_streams a:0 -show_entries stream=codec_name,sample_rate,bit_rate -of default=noprint_wrappers=1 ${source});
audio_codec_name=${codec_name}
audio_sample_rate=${sample_rate}
if [[ ${bit_rate} =~ [^[:digit:]] ]]
then
    audio_bit_rate=-1
else
    audio_bit_rate=$((${bit_rate}/1000))
fi
echo_file_info "------- AUDIO STREAM 0 -------"
echo_file_info "Codec: ${audio_codec_name}"
echo_file_info "Sample rate (Hz): ${audio_sample_rate}"
echo_file_info "Bitrate (kbps): ${audio_bit_rate}"
echo_file_info "---------------------\n"

encoding_required=false

# 0: transcoding not required
# 1: bitrate too high
# 2: video codec not supported
# 3: audio codec not supported

# Filter out videos for which original file can used for playback.
echo_info "Checking format and video stream 0 bitrate..."
if [ "$format_bit_rate_kbps" -ge "$max_supported_bitrate" ]; then
	echo_warn "Bitrate too high, re-encoding required"
	original_bitrate=${format_bit_rate_kbps}
	encoding_required=true
else
	if [ "$video_bitrate" -ge "$max_supported_bitrate" ]; then
		echo_warn "Bitrate too high, re-encoding required"
		original_bitrate=${video_bitrate}
		encoding_required=true
	else
		echo_warn "No need to change bitrate"
		original_bitrate=${format_bit_rate_kbps}
	fi
fi

# Check if the main format is supported natively by myCloud video players on client side.
if [ "${supported_video_formats}" != "${format_format_name}" ] ; then
	echo_warn "Found format to convert: ${format_format_name}"
	encoding_required=true
fi

# Check if the video codec is supported natively by myCloud video players on client side.
if [ "${supported_video_codec}" != "${video_codec_name}" ] ; then
	echo_warn "Found video codec to convert: ${video_codec_name}"
	encoding_required=true
fi

# Check if the audio codec is supported natively by myCloud video players on client side.
if [ "${supported_audio_codec}" != "${audio_codec_name}" ] ; then
	echo_warn "Found audio codec to convert: ${audio_codec_name}"
	encoding_required=true
fi


if [ "$encoding_required" = true ] ; then
    echo_info "Setting encoding parameters"
    
	# Static parameters.
	# Constant Rate Factor (CRF): 18 is considered to be visually lossless or nearly so (bigger file size).
	# Profile compatibility: https://trac.ffmpeg.org/wiki/Encode/H.264#Compatibility
	# Preset: medium (default preset, no need to specify it).
	# Faststart for web video: -movflags +faststart (this will move some info to the beginning of the file and allow the video to begin playing before it is completely downloaded).
	static_params="-c:a aac -ar 48000 -c:v h264 -profile:v high -level 4.0 -crf 18 -movflags +faststart"
	
	# Misc parameters.
	misc_params="-hide_banner -y"
	
	cmd=""	

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
	
	# If the original video bitrate is less or equal, probably it's better to use it.
	int_bitrate="$(echo "`echo ${bitrate} | grep -oE '[[:digit:]]+'`" | bc)"
	if [ "${int_bitrate}" -gt "${original_bitrate}" ]; then
		bitrate="${original_bitrate}k"
	fi
	
	# If the original audio bitrate is less or equal, probably it's better to use it.
	int_audiorate="$(echo "`echo ${audiorate} | grep -oE '[[:digit:]]+'`" | bc)"
	if [ "$int_audiorate" -gt "$audio_bit_rate" ]; then
		audiorate="${audio_bit_rate}k"
	fi
	
	maxrate="$(echo "`echo ${bitrate} | grep -oE '[[:digit:]]+'`*${max_bitrate_ratio}" | bc)"
  	bufsize="$(echo "`echo ${bitrate} | grep -oE '[[:digit:]]+'`*${rate_monitor_buffer_ratio}" | bc)"
	
	cmd+="${static_params}"
	cmd+=" -b:v ${bitrate} -maxrate ${maxrate%.*}k -bufsize ${bufsize%.*}k -b:a ${audiorate}"
	
	cmd+=" NEW_${target}.mp4"
	
	# Start conversion.
	echo_info "Command to execute:\nffmpeg ${misc_params} -i ${source} ${cmd}"
	if [ "$dry_run" = false ] ; then
		ffmpeg ${misc_params} -i ${source} ${cmd}
	fi
	
	echo_info "Done"
else
	echo_info "Re-encoding not necessary, nothing to do. Original file can be played."
fi
