package com.eventcart.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;

@WebMvcTest(HelloWorldController.class)
public class HelloWorldControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void testGetMessage() throws Exception {
        mockMvc.perform(get("/message"))
                .andExpect(status().isOk())
                .andExpect(content().string("Hello World from eventcart"));
    }

    @Test
    public void testGetResponse() throws Exception {
        mockMvc.perform(get("/response"))
                .andExpect(status().isOk())
                .andExpect(content().string("Learning CI CD..."));
    }

    @Test
    public void testGetAnsible() throws Exception {
        mockMvc.perform(get("/ansible"))
                .andExpect(status().isOk())
                .andExpect(content().string("Working with Ansible......."));
    }

    @Test
    public void testTest() throws Exception {
        mockMvc.perform(get("/test"))
                .andExpect(status().isOk())
                .andExpect(content().string("Test......"));
    }

    @Test
    public void testLove() throws Exception {
        mockMvc.perform(get("/wife"))
                .andExpect(status().isOk())
                .andExpect(content().string("Gayathri I LOVE YOU......"));
    }

    @Test
    public void testPipeline() throws Exception {
        mockMvc.perform(get("/pipeline"))
                .andExpect(status().isOk())
                .andExpect(content().string("Testing pipeline......"));
    }

    @Test
    public void testKube() throws Exception {
        mockMvc.perform(get("/kube"))
                .andExpect(status().isOk())
                .andExpect(content().string("Welcome to Kubernetes......"));
    }

    @Test
    public void testVikas() throws Exception {
        mockMvc.perform(get("/vikas"))
                .andExpect(status().isOk())
                .andExpect(content().string("JUNIER ENGINEER IN RAILWAYS.."));
    }

    @Test
    public void testAjith() throws Exception {
        mockMvc.perform(get("/ajith"))
                .andExpect(status().isOk())
                .andExpect(content().string("Manager in Bajaj.........."));
    }

    @Test
    public void testPrabhas() throws Exception {
        mockMvc.perform(get("/prabhas"))
                .andExpect(status().isOk())
                .andExpect(content().string("India's Biggest star........."));
    }

    @Test
    public void testVishal() throws Exception {
        mockMvc.perform(get("/vishal"))
                .andExpect(status().isOk())
                .andExpect(content().string("Common Man........."));
    }
}