package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.Locker;
import com.sejong.sjc_app.dto.LockerResponse;
import com.sejong.sjc_app.repository.LockerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/lockers")
@RequiredArgsConstructor
public class LockerController {

    private final LockerRepository lockerRepository;

    // 전체 사물함 목록 조회 (로그인 필요)
    @GetMapping
    public List<LockerResponse> getLockers(Authentication authentication) {
        String studentId = authentication.getName();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        return lockerRepository.findAll().stream()
                .map(locker -> {
                    boolean canSeePassword = isAdmin || studentId.equals(locker.getCurrentUserId());
                    return LockerResponse.from(locker, canSeePassword);
                })
                .collect(Collectors.toList());
    }

    // 사용 가능한 사물함만 조회
    @GetMapping("/available")
    public List<LockerResponse> getAvailableLockers() {
        return lockerRepository.findByStatus(Locker.Status.AVAILABLE).stream()
                .map(locker -> LockerResponse.from(locker, false))
                .collect(Collectors.toList());
    }

    // 사물함 신청 (로그인 필요)
    @PostMapping("/{id}/apply")
    public LockerResponse applyLocker(Authentication authentication, @PathVariable Long id) {
        String studentId = authentication.getName();

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.AVAILABLE) {
            throw new RuntimeException("이미 사용 중이거나 신청할 수 없는 사물함입니다.");
        }

        LocalDateTime now = LocalDateTime.now();

        Locker updated = Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(Locker.Status.IN_USE)
                .currentUserId(studentId)
                .assignedAt(now)
                .dueDate(now.plusDays(14))
                .build();

        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, true);
    }

    // 사물함 반납 (본인 또는 ADMIN)
    @PostMapping("/{id}/return")
    public LockerResponse returnLocker(Authentication authentication, @PathVariable Long id) {
        String studentId = authentication.getName();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.IN_USE) {
            throw new RuntimeException("사용 중인 사물함이 아닙니다.");
        }

        boolean isOwner = studentId.equals(locker.getCurrentUserId());
        if (!isOwner && !isAdmin) {
            throw new RuntimeException("본인 또는 관리자만 반납할 수 있습니다.");
        }

        Locker released = Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(Locker.Status.AVAILABLE)
                .currentUserId(null)
                .assignedAt(null)
                .dueDate(null)
                .build();

        Locker saved = lockerRepository.save(released);
        return LockerResponse.from(saved, false);
    }

    // 사물함 상태 강제 변경 (ADMIN만) - 고장 처리 / 복구 등
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public LockerResponse updateStatus(@PathVariable Long id,
                                       @RequestParam Locker.Status status) {

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (status == Locker.Status.IN_USE) {
            throw new RuntimeException("이 API로는 IN_USE로 직접 변경할 수 없습니다. 학생의 신청을 통해서만 가능합니다.");
        }

        Locker updated = Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(status)
                .currentUserId(null)
                .assignedAt(null)
                .dueDate(null)
                .build();

        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, true);
    }
}