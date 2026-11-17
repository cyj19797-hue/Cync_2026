package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "school_notice")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SchoolNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private Long articleNo;

    private String title;

    @Column(length = 5000)
    private String content;

    private String category;
    private boolean isNotice;
    private String postedDate;
    private Integer viewCount;
    private String sourceUrl;
    private LocalDateTime crawledAt;

    // 안내사항 관련 날짜 (없으면 둘 다 null, 하루면 시작일 = 종료일)
    private LocalDate eventStartDate;
    private LocalDate eventEndDate;
}