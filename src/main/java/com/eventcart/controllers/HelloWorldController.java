package com.eventcart.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.eventcart.entity.Student;
import com.eventcart.repository.StudentRepository;

import lombok.extern.log4j.Log4j2;

@Log4j2
@RestController
public class HelloWorldController {

	@Autowired
	private StudentRepository studentRepository;

	@PostMapping("/create")
	public Student create(@RequestBody Student student) {

		return studentRepository.save(student);

	}

	@GetMapping("/students")
	public List<Student> getStudents() {

		return studentRepository.findAll();

	}

	@Value("${DB_HOST:NOT_SET}")
	private String DB_HOST;

	@GetMapping(path = "message")
	public String getMessage() {
		return "Hello World from eventcart: " + DB_HOST;
	}

}
