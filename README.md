# FFMpeg experiments
Playground for FFProbe and FFMpeg.
This code is not production ready (actually not even complete) and there is no plan to officially improve and support it.
Updates might come from time to time or maybe never.

### SpringBoot REST API
Run the service, then get video file information uploading a file (max file size is 1024 MB).

```
curl --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' -F 'file=@test.mp4;type=video/mp4' localhost:8080/api/probe
```

### Encoding script
The following script is not part of the REST API and it can be used separately.
The idea of this script is to probe a video file and if some conditions are not met (bitrate, video and audio codec type), then the file is encoded used a standard configuration.

https://github.com/fasteque/streaming/blob/master/scripts/create_vod_adaptive_stream.sh

### Requirements
Both services (REST API + script) assume that you have FFMpeg installed.

## Credits
SpringBoot REST API: https://github.com/lgazda/springboot-rest-ffmpeg

Bash script: https://gist.github.com/mrbar42/ae111731906f958b396f30906004b3fa
