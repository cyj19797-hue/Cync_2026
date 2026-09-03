package com.sejong.sjc_app.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "locker")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Locker {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private Integer lockerNumber;

    private String location;

    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Status status = Status.AVAILABLE;

    private String currentUserId;

    private LocalDateTime assignedAt;

    public enum Status {
        AVAILABLE, PENDING, IN_USE, BROKEN
    }
}