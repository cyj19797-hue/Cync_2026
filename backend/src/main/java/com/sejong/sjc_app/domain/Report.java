package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "report")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    private TargetType targetType;

    private Long targetId;

    private String reporterId;

    @Enumerated(EnumType.STRING)
    private Reason reason;

    @Column(length = 1000)
    private String detail;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Status status = Status.PENDING;

    private LocalDateTime createdAt;

    public enum TargetType {
        POST, COMMENT
    }

    public enum Reason {
        SPAM, ABUSE, PRIVACY, FALSE_INFO, OTHER
    }

    public enum Status {
        PENDING, RESOLVED
    }
}