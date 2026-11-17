package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
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

    private String imageUrl;

    private String authorId;
    private String authorName;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 안내사항 관련 날짜 (없으면 둘 다 null, 하루면 시작일 = 종료일)
    private LocalDate eventStartDate;
    private LocalDate eventEndDate;
}