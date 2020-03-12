package com.example.simple.web;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class HelloController {

    @RequestMapping("/")
    public String index() {
        String environment = System.getenv("ENVIRONMENT");
        String response = "<html><head><title>SimpleApp</title></head><body><h1>Super Simple Java App</h1>";
        if (!StringUtils.isEmpty(environment)) {
            response += "\n\n<h2>Environment: " + environment + "</h2>";
        }
        response += "</body></html>";
        return response;
    }

}