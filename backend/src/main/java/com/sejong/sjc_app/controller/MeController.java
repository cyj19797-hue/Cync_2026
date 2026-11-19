package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me")
@RequiredArgsConstructor
public class MeController {

    private final UserRepository userRepository;

    // 내 프로필 조회 (로그인 필요)
    @GetMapping
    public User getMyProfile(Authentication authentication) {
        String studentId = authentication.getName();

        return userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
    }

    // 이용약관·개인정보처리방침 동의 기록 (로그인 필요)
    // 이미 동의한 사용자가 다시 호출해도 최초 동의 시각은 바뀌지 않음
    @PostMapping("/terms-agreement")
    public User agreeTerms(Authentication authentication) {
        String studentId = authentication.getName();

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        return userRepository.save(user.agreeTerms());
    }

    // 닉네임 / 프로필 색상 설정 (로그인 필요)
    @PutMapping("/profile")
    public User updateMyProfile(Authentication authentication,
                                @RequestParam String nickname,
                                @RequestParam User.ProfileColor profileColor) {

        String studentId = authentication.getName();

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        if (!nickname.equals(user.getNickname()) && userRepository.existsByNickname(nickname)) {
            throw new RuntimeException("이미 사용 중인 닉네임입니다.");
        }

        User updated = user.toBuilder()
                .nickname(nickname)
                .profileColor(profileColor)
                .build();

        return userRepository.save(updated);
    }
}