package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.dto.SejongMemberInfo;
import com.sejong.sjc_app.dto.TokenResponse;
import com.sejong.sjc_app.repository.UserRepository;
import com.sejong.sjc_app.service.JwtTokenProvider;
import com.sejong.sjc_app.service.SejongPortalLoginService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SejongPortalLoginService loginService;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;

    @PostMapping("/login")
    public TokenResponse login(@RequestParam String id,
                               @RequestParam String password) throws Exception {

        // 1. 세종대 포털 로그인 + 학생 정보 크롤링
        SejongMemberInfo memberInfo = loginService.getMemberInfo(id, password);

        // 2. DB에서 User 조회, 없으면 자동 등록 (기본 USER)
        User user = userRepository.findById(memberInfo.getStudentId())
                .orElseGet(() -> {
                    User newUser = User.builder()
                            .studentId(memberInfo.getStudentId())
                            .name(memberInfo.getName())
                            .role(User.Role.USER)
                            .build();
                    return userRepository.save(newUser);
                });

        // 3. JWT 토큰 발급 (DB에 저장된 role 사용)
        String token = jwtTokenProvider.generateToken(memberInfo, user.getRole().name());

        // 4. 토큰 + 학생 정보 반환
        return TokenResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .memberInfo(memberInfo)
                .build();
    }
}