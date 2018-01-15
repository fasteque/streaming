package com.fasteque.streaming.domain;

import net.bramp.ffmpeg.probe.FFmpegFormat;
import net.bramp.ffmpeg.probe.FFmpegProbeResult;
import net.bramp.ffmpeg.probe.FFmpegStream;
import org.springframework.stereotype.Component;

import java.util.List;

import static java.util.Arrays.asList;
import static java.util.Objects.nonNull;
import static java.util.Objects.requireNonNull;
import static java.util.stream.Collectors.toList;
import static net.bramp.ffmpeg.probe.FFmpegStream.CodecType.AUDIO;
import static net.bramp.ffmpeg.probe.FFmpegStream.CodecType.VIDEO;
import static org.apache.commons.lang3.RandomStringUtils.randomAlphanumeric;
import static org.apache.commons.lang3.RandomUtils.nextLong;

@Component
public class ProbeResultFactory {
    public ProbeResult from(FFmpegProbeResult probeResult) {
        requireNonNull(probeResult);

        ProbeResult.VideoFormat format = nonNull(probeResult.getFormat()) ? createVideoFormat(probeResult.getFormat()) : null;
        List<ProbeResult.Codec> codecs = probeResult.getStreams()
                .stream()
                .map(this::createCodec)
                .collect(toList());
        return new ProbeResult(format, codecs);
    }

    public ProbeResult.VideoFormat createVideoFormat(FFmpegFormat format) {
        requireNonNull(format);
        return new ProbeResult.VideoFormat(format.duration, format.size, format.bit_rate);
    }

    public ProbeResult.Codec createCodec(FFmpegStream stream) {
        requireNonNull(stream);
        return new ProbeResult.Codec(stream.codec_name, stream.codec_long_name, stream.bit_rate, stream.codec_type == AUDIO ? ProbeResult.CodecType.AUDIO : ProbeResult.CodecType.VIDEO);
    }

    public static FFmpegProbeResult randomFFmpegProbeResult() {
        FFmpegFormat fFmpegFormat = new FFmpegFormat();
        fFmpegFormat.bit_rate = nextLong(100, 1000000);
        fFmpegFormat.duration = nextLong(100, 10000000);
        fFmpegFormat.size = nextLong(100, 100000000);

        FFmpegStream streamVideo = new FFmpegStream();
        streamVideo.bit_rate = nextLong(100, 1000000);;
        streamVideo.codec_name = randomAlphanumeric(5);
        streamVideo.codec_long_name = "RANDOM MOCK " + randomAlphanumeric(5);
        streamVideo.codec_type = VIDEO;

        FFmpegStream streamAudio = new FFmpegStream();
        streamAudio.bit_rate = nextLong(100, 1000000);;
        streamAudio.codec_name = randomAlphanumeric(5);
        streamAudio.codec_long_name = randomAlphanumeric(5);
        streamAudio.codec_type = AUDIO;

        FFmpegProbeResult result = new FFmpegProbeResult();
        result.format = fFmpegFormat;
        result.streams = asList(streamAudio, streamVideo);
        return result;

    }
}
