package com.sejong.sjc_app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.security.Security;
import java.util.Arrays;
import java.util.stream.Collectors;

@SpringBootApplication
@EnableScheduling
public class SjcAppApplication {

	public static void main(String[] args) {
		allowLegacyTlsForSejong();   // 반드시 스프링 시작 전에 실행
		SpringApplication.run(SjcAppApplication.class, args);
	}

	// 세종대 서버가 쓰는 TLS_RSA 계열 암호를 새 JDK가 막아둔 목록에서 제외
	private static void allowLegacyTlsForSejong() {
		String key = "jdk.tls.disabledAlgorithms";
		String before = Security.getProperty(key);
		if (before == null) {
			return;
		}

		String after = Arrays.stream(before.split(","))
				.map(String::trim)
				.filter(s -> !s.isEmpty())
				.filter(s -> !s.startsWith("TLS_RSA_"))
				.collect(Collectors.joining(", "));

		Security.setProperty(key, after);

		// 배포 후 로그에서 확인용
		System.out.println("[TLS] disabledAlgorithms 변경 전: " + before);
		System.out.println("[TLS] disabledAlgorithms 변경 후: " + after);
	}
}