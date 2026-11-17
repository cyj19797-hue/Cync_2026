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
    private String currentUserId;   // 관리자 또는 본인 사물함일 때만 채워짐 (그 외 null)
    private boolean mine;           // 지금 조회한 사람의 사물함인지
    private LocalDateTime assignedAt;
    private String password;

    // viewerId: 조회한 사람의 학번 (모르면 null), isAdmin: 조회한 사람이 관리자인지
    public static LockerResponse from(Locker locker, boolean includePassword, String viewerId, boolean isAdmin) {
        boolean mine = viewerId != null && viewerId.equals(locker.getCurrentUserId());

        return LockerResponse.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .status(locker.getStatus())
                .currentUserId((isAdmin || mine) ? locker.getCurrentUserId() : null)
                .mine(mine)
                .assignedAt(locker.getAssignedAt())
                .password(includePassword ? locker.getPassword() : null)
                .build();
    }
}
