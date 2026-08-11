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

    private Long postId;         // 어느 게시글에 달린 댓글인지

    @Column(length = 1000)
    private String content;

    private String authorId;
    private String authorName;

    private boolean isAnonymous;

    private LocalDateTime createdAt;
}