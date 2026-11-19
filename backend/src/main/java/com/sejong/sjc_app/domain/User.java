package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Builder(toBuilder = true)
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    private String studentId;

    private String name;

    @Enumerated(EnumType.STRING)
    private Role role;

    @Column(unique = true)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ProfileColor profileColor = ProfileColor.GRAY;

    @Builder.Default
    private boolean banned = false;

    private LocalDateTime banExpiresAt;

    private String banReason;

    @Builder.Default
    private boolean withdrawn = false;

    private LocalDateTime withdrawnAt;

    // 이용약관·개인정보처리방침 동의 여부 (최초 로그인 때 한 번만 받음)
    @Builder.Default
    private boolean termsAgreed = false;

    private LocalDateTime termsAgreedAt;

    public enum Role {
        USER, ADMIN
    }

    public enum ProfileColor {
        RED, ORANGE, YELLOW, GREEN, MINT, BLUE, PURPLE, PINK, GRAY
    }

    public boolean isCurrentlyBanned() {
        if (!banned) {
            return false;
        }
        if (banExpiresAt == null) {
            return true; // 영구 정지
        }
        return banExpiresAt.isAfter(LocalDateTime.now());
    }

    // 탈퇴 처리: 개인정보는 비우고 정지 기록은 유지
    public User withdraw() {
        return this.toBuilder()
                .name(null)
                .nickname(null)
                .profileColor(ProfileColor.GRAY)
                .role(Role.USER)
                .withdrawn(true)
                .withdrawnAt(LocalDateTime.now())
                .termsAgreed(false)
                .termsAgreedAt(null)
                .build();
    }

    // 약관 동의 처리: 이미 동의했으면 최초 동의 시각을 그대로 유지
    public User agreeTerms() {
        if (termsAgreed) {
            return this;
        }
        return this.toBuilder()
                .termsAgreed(true)
                .termsAgreedAt(LocalDateTime.now())
                .build();
    }

    // 재가입: 정지 기록은 그대로 두고 계정만 되살림
    public User rejoin(String name, String nickname) {
        return this.toBuilder()
                .name(name)
                .nickname(nickname)
                .withdrawn(false)
                .withdrawnAt(null)
                .build();
    }
}