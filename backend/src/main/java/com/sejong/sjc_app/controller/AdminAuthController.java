package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.dto.SejongMemberInfo;
import com.sejong.sjc_app.dto.TokenResponse;
import com.sejong.sjc_app.repository.UserRepository;
import com.sejong.sjc_app.service.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AdminAuthController {

    private static final String ADMIN_NAME = "운영진";

    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Value("${admin.login-id:}")
    private String adminLoginId;

    @Value("${admin.password-hash:}")
    private String adminPasswordHash;

    // 관리자 전용 로그인 (세종 포털을 거치지 않음)
    @PostMapping("/admin-login")
    public TokenResponse adminLogin(@RequestParam String id,
                                    @RequestParam String password) {

        // 설정이 없으면 이 기능 자체가 꺼진 것으로 취급
        if (adminLoginId.isBlank() || adminPasswordHash.isBlank()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }

        // 아이디와 비밀번호를 항상 둘 다 검사해서 응답 시간 차이로 추측하기 어렵게 함
        boolean idMatches = MessageDigest.isEqual(
                adminLoginId.getBytes(StandardCharsets.UTF_8),
                id.getBytes(StandardCharsets.UTF_8));
        boolean passwordMatches = passwordEncoder.matches(password, adminPasswordHash);

        if (!idMatches || !passwordMatches) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "아이디 또는 비밀번호가 올바르지 않습니다.");
        }

        // 관리자 계정 행이 없으면 만들고, 있으면 ADMIN 상태로 맞춤
        User admin = userRepository.findById(adminLoginId)
                .map(existing -> existing.toBuilder()
                        .name(ADMIN_NAME)
                        .nickname(ADMIN_NAME)
                        .role(User.Role.ADMIN)
                        .withdrawn(false)
                        .withdrawnAt(null)
                        .build())
                .orElseGet(() -> User.builder()
                        .studentId(adminLoginId)
                        .name(ADMIN_NAME)
                        .nickname(ADMIN_NAME)
                        .role(User.Role.ADMIN)
                        .build());
        userRepository.save(admin);

        SejongMemberInfo memberInfo = SejongMemberInfo.builder()
                .major(ADMIN_NAME)
                .studentId(adminLoginId)
                .name(ADMIN_NAME)
                .build();

        String token = jwtTokenProvider.generateToken(memberInfo, User.Role.ADMIN.name());

        return TokenResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .memberInfo(memberInfo)
                .build();
    }
}