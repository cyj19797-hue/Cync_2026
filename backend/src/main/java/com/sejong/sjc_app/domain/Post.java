package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "post")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(length = 5000)
    private String content;

    private String authorId;      // 실제 학번 (익명이어도 항상 저장)
    private String authorName;    // 실제 이름

    private String authorNickname;

    @Enumerated(EnumType.STRING)
    private User.ProfileColor authorColor;

    private boolean isAnonymous;  // JSON에서는 "anonymous"로 나감

    @Builder.Default
    private Integer viewCount = 0;

    @Builder.Default
    private Integer likeCount = 0;

    @Builder.Default
    private Integer commentCount = 0;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}