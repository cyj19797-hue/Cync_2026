package com.sejong.sjc_app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SjcAppApplication {

	public static void main(String[] args) {
		SpringApplication.run(SjcAppApplication.class, args);
	}

}
