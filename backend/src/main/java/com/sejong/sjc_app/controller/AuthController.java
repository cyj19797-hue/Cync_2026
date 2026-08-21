package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.dto.SejongMemberInfo;
import com.sejong.sjc_app.dto.TokenResponse;
import com.sejong.sjc_app.repository.UserRepository;
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

    @PostMapping("/login")
    public TokenResponse login(@RequestParam String id,
                               @RequestParam String password) throws Exception {

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