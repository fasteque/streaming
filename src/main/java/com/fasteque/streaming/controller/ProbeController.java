package com.fasteque.streaming.controller;

import com.fasteque.streaming.domain.ProbeResult;
import com.fasteque.streaming.domain.RestApiResponse;
import com.fasteque.streaming.service.ProbeService;
import com.fasteque.streaming.validator.MultipartVideoFileValidator;
import io.swagger.annotations.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import static com.fasteque.streaming.validator.MultipartVideoFileValidator.VIDEO_TYPE;
import static org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE;
import static org.springframework.util.MimeTypeUtils.APPLICATION_JSON_VALUE;

/**
 * curl --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' -F 'file=@test.mp4;type=video/mp4' localhost:8080/api/probe
 */
@ApiController
@Api(description="Operation for video probing.", tags = {"probe"})
public class ProbeController {
    private final ProbeService probeService;
    private final MultipartVideoFileValidator validator;

    @Autowired
    public ProbeController(ProbeService probeService, MultipartVideoFileValidator validator) {
        this.probeService = probeService;
        this.validator = validator;
    }

    /**
     * Post and multipart/form-data for browser/js compatibility.
     */
    @ApiOperation(value = "Probes a file and returns basic video information.", response = ProbeResult.class, produces = APPLICATION_JSON_VALUE, consumes = MULTIPART_FORM_DATA_VALUE)
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "Successful probe", response = ProbeResult.class),
            @ApiResponse(code = 400, message = "Bad Request"),
            @ApiResponse(code = 405, message = "Wrong http method was used"),
            @ApiResponse(code = 406, message = "For not acceptable content type"),
            @ApiResponse(code = 415, message = "Wrong main request mime type"),
            @ApiResponse(code = 500, message = "Internal server error", response = RestApiResponse.class)})
    @PostMapping(path = "probe",
            consumes = MULTIPART_FORM_DATA_VALUE,
            produces = APPLICATION_JSON_VALUE,
            headers = "Accept=application/json")
    public ProbeResult probe(@ApiParam(value = "file to probe", required = true)
                                       @RequestParam("file") MultipartFile file) throws Exception {
        validator.requiresMediaType(file, VIDEO_TYPE);
        return probeService.probe(file.getInputStream());
    }
}