package com.fasteque.streaming.domain;

import net.bramp.ffmpeg.FFprobe;
import net.bramp.ffmpeg.probe.FFmpegProbeResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.nio.file.Path;

@Component
public class FFMpegProbe {
    private final FFprobe ffprobe;
    private final ProbeResultFactory resultFactory;

    @Autowired
    public FFMpegProbe(FFprobe ffprobe, ProbeResultFactory resultFactory) {
        this.ffprobe = ffprobe;
        this.resultFactory = resultFactory;
    }

    public ProbeResult probeFile(Path path) throws ProbeException {
        try {
            /*
                Default implementation run the following command:
                ffprobe -v quiet -print_format json -show_error -show_format -show_streams INPUT_FILE
             */
            FFmpegProbeResult probeResult = ffprobe.probe(path.toString());
            return resultFactory.from(probeResult);
        } catch (Exception e) {
            throw new ProbeException(e);
        }
    }

    public static class ProbeException extends Exception {
        public ProbeException(Throwable ex) {
            super(ex);
        }

        @Override
        public String toString() {
            return "Unable to probe file";
        }
    }
}
