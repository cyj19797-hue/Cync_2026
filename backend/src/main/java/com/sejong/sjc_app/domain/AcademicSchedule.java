package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "academic_schedule")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademicSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private LocalDate startDate;

    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    private Source source;

    private String authorId;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    public enum Source {
        SCHOOL, STUDENT_COUNCIL
    }
}