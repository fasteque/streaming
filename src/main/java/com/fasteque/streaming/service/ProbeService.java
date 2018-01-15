package com.fasteque.streaming.service;

import com.fasteque.streaming.domain.FFMpegProbe;
import com.fasteque.streaming.domain.ProbeResult;
import com.fasteque.streaming.domain.TemporaryFileStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;

@Service
public class ProbeService {
    private final TemporaryFileStore fileStore;
    private final FFMpegProbe probe;

    @Autowired
    public ProbeService(TemporaryFileStore fileStore, FFMpegProbe probe) {
        this.fileStore = fileStore;
        this.probe = probe;
    }

    /**
     * @param inputStream for file to probe.
     * @return {@link ProbeResult}
     * @throws {@link FFMpegProbe.ProbeException}
     * @throws IOException
     */
    public ProbeResult probe(InputStream inputStream) throws FFMpegProbe.ProbeException, IOException {
        Path file = null;
        try {
            file = fileStore.store(inputStream);
            return probe.probeFile(file);
        } finally {
            fileStore.delete(file);
        }
    }
}