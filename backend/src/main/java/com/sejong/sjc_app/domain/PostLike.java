package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "post_like", uniqueConstraints = {@UniqueConstraint(columnNames = {"postId", "studentId"})})
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostLike {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long postId;
    private String studentId;
}