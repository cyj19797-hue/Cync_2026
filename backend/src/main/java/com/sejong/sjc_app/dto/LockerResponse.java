package com.sejong.sjc_app.dto;

import com.sejong.sjc_app.domain.Locker;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class LockerResponse {
    private Long id;
    private Integer lockerNumber;
    private String location;
    private Locker.Status status;
    private String currentUserId;
    private LocalDateTime assignedAt;
    private String password;

    public static LockerResponse from(Locker locker, boolean includePassword) {
        return LockerResponse.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .status(locker.getStatus())
                .currentUserId(locker.getCurrentUserId())
                .assignedAt(locker.getAssignedAt())
                .password(includePassword ? locker.getPassword() : null)
                .build();
    }
}