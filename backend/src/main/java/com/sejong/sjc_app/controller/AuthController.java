package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.dto.SejongMemberInfo;
import com.sejong.sjc_app.dto.TokenResponse;
import com.sejong.sjc_app.repository.UserRepository;
import com.sejong.sjc_app.service.AdminLoginService;
import com.sejong.sjc_app.service.JwtTokenProvider;
import com.sejong.sjc_app.service.SejongPortalLoginService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Random;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SejongPortalLoginService loginService;
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    private final AdminLoginService adminLoginService;

    @PostMapping("/login")
    public TokenResponse login(@RequestParam String id,
                               @RequestParam String password) throws Exception {

        // 관리자 아이디면 세종 포털을 거치지 않고 관리자 비밀번호로 검증
        if (adminLoginService.isAdminId(id)) {
            return adminLoginService.login(id, password);
        }

        SejongMemberInfo memberInfo = loginService.getMemberInfo(id, password);

        User user = userRepository.findById(memberInfo.getStudentId())
                .orElseGet(() -> {
                    User newUser = User.builder()
                            .studentId(memberInfo.getStudentId())
                            .name(memberInfo.getName())
                            .role(User.Role.USER)
                            .nickname(generateUniqueNickname())
                            .profileColor(User.ProfileColor.GRAY)
                            .build();
                    return userRepository.save(newUser);
                });

        // 탈퇴했던 계정이 다시 로그인하면 되살림 (정지 기록은 그대로 승계)
        if (user.isWithdrawn()) {
            user = userRepository.save(user.rejoin(memberInfo.getName(), generateUniqueNickname()));
        }

        String token = jwtTokenProvider.generateToken(memberInfo, user.getRole().name());

        return TokenResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .memberInfo(memberInfo)
                .build();
    }

    private String generateUniqueNickname() {
        Random random = new Random();
        String nickname;
        do {
            nickname = "익명" + (100000 + random.nextInt(900000));
        } while (userRepository.existsByNickname(nickname));
        return nickname;
    }
}