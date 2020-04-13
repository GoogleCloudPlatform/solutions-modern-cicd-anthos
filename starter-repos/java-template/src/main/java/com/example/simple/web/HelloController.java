// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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