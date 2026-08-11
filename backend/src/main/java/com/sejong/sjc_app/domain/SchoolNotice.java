package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

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

    private String category;

    private boolean isNotice;

    private String postedDate;

    private Integer viewCount;

    private String sourceUrl;

    private LocalDateTime crawledAt;
}