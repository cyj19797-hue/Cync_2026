package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

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

    public enum Role {
        USER, ADMIN
    }

    public enum ProfileColor {
        RED, ORANGE, YELLOW, GREEN, MINT, BLUE, PURPLE, PINK, GRAY
    }
}