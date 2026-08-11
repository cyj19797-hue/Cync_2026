package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "student_council_notice")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentCouncilNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(length = 5000)
    private String content;

    private String authorId;

    private String authorName;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}