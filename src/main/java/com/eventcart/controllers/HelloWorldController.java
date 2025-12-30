package com.eventcart.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloWorldController {
	
	
	@GetMapping(path = "message")
	public String getMessage() {
		return "Hello World from eventcart";
	}
	
	@GetMapping(path = "response")
	public String getResponse() {
		return "Learning CI CD...";
	}

}
