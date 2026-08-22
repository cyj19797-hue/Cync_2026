package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserRepository userRepository;

    // 정지 부여 (기간 지정 또는 영구)
    @PostMapping("/{studentId}/ban")
    @PreAuthorize("hasRole('ADMIN')")
    public User banUser(@PathVariable String studentId,
                        @RequestParam(required = false) Integer days,
                        @RequestParam String reason) {

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        LocalDateTime banExpiresAt = (days != null) ? LocalDateTime.now().plusDays(days) : null;

        User updated = User.builder()
                .studentId(user.getStudentId())
                .name(user.getName())
                .role(user.getRole())
                .nickname(user.getNickname())
                .profileColor(user.getProfileColor())
                .banned(true)
                .banExpiresAt(banExpiresAt)
                .banReason(reason)
                .build();

        return userRepository.save(updated);
    }

    // 정지 해제
    @PostMapping("/{studentId}/unban")
    @PreAuthorize("hasRole('ADMIN')")
    public User unbanUser(@PathVariable String studentId) {

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        User updated = User.builder()
                .studentId(user.getStudentId())
                .name(user.getName())
                .role(user.getRole())
                .nickname(user.getNickname())
                .profileColor(user.getProfileColor())
                .banned(false)
                .banExpiresAt(null)
                .banReason(null)
                .build();

        return userRepository.save(updated);
    }
}