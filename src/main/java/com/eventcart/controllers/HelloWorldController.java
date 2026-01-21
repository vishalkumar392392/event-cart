package com.eventcart.controllers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.log4j.Log4j;
import lombok.extern.log4j.Log4j2;

@Log4j2
@RestController
public class HelloWorldController {
	
	
	@Value("${DB_HOST:NOT_SET}")
	private String DB_HOST;
	
	@GetMapping(path = "message")
	public String getMessage() {
		log.info("DB Host = {}", System.getenv("DB_HOST"));
		return "Hello World from eventcart: " +DB_HOST;
	}
	
	@GetMapping(path = "response")
	public String getResponse() {
		return "Learning CI CD...";
	}
	
	@GetMapping(path = "ansible")
	public String getAnsible() {
		return "Working with Ansible.......";
	}
	
	@GetMapping(path = "test")
	public String test() {
		return "Test......";
	}
	
	@GetMapping(path = "wife")
	public String love() {
		return "Gayathri I LOVE YOU......";
	}
	
	@GetMapping(path = "pipeline")
	public String pipeline() {
		return "Testing pipeline......";
	}
	
	@GetMapping(path = "kube")
	public String kube() {
		return "Welcome to Kubernetes......";
	}
	
	@GetMapping(path = "vikas")
	public String vikas() {
		return "JUNIER ENGINEER IN RAILWAYS..";
	}
	
	@GetMapping(path = "ajith")
	public String ajith() {
		return "Manager in Bajaj..........";
	}
	
	@GetMapping(path = "prabhas")
	public String prabhas() {
		return "India's Biggest star.........";
	}
	@GetMapping(path = "vishal")
	public String vishal() {
		return "Common Man.........";
	}

}
