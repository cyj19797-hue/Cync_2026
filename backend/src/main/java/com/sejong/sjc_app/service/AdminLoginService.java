package com.sejong.sjc_app.service;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.dto.SejongMemberInfo;
import com.sejong.sjc_app.dto.TokenResponse;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AdminLoginService {

    private static final String ADMIN_NAME = "운영진";

    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Value("${admin.login-id:}")
    private String adminLoginId;

    @Value("${admin.password-hash:}")
    private String adminPasswordHash;

    // 설정이 있고 입력한 아이디가 관리자 아이디일 때만 관리자 경로로 처리
    public boolean isAdminId(String id) {
        return !adminLoginId.isBlank()
                && !adminPasswordHash.isBlank()
                && adminLoginId.equals(id);
    }

    public TokenResponse login(String id, String password) {
        if (!passwordEncoder.matches(password, adminPasswordHash)) {
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