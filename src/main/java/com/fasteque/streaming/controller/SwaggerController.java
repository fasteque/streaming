package com.fasteque.streaming.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class SwaggerController {
    @RequestMapping({"/", "index.html"})
    public String swagger() {
        return "redirect:/swagger-ui.html";
    }
}
