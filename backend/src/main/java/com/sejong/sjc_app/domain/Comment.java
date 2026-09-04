package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "comment")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Comment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long postId;

    private Long parentCommentId;

    @Column(length = 1000)
    private String content;

    private String authorId;
    private String authorName;
    private String authorNickname;

    @Enumerated(EnumType.STRING)
    private User.ProfileColor authorColor;

    private boolean isAnonymous;

    @Builder.Default
    private boolean isDeleted = false;

    private LocalDateTime createdAt;
}