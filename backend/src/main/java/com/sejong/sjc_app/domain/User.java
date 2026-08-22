package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Builder
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
}