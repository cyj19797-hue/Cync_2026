package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "app_notice")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(length = 3000)
    private String content;

    @Builder.Default
    private boolean isPopup = false;

    private String authorId;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}