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

    // 관리자용 - 승인 대기 중인 신청 목록 조회
    @GetMapping("/pending")
    @PreAuthorize("hasRole('ADMIN')")
    public List<LockerResponse> getPendingLockers() {
        return lockerRepository.findByStatus(Locker.Status.PENDING).stream()
                .map(locker -> LockerResponse.from(locker, true))
                .collect(Collectors.toList());
    }

    // 사물함 신청 (로그인 필요) - AVAILABLE -> PENDING
    @PostMapping("/{id}/apply")
    public LockerResponse applyLocker(Authentication authentication, @PathVariable Long id) {
        String studentId = authentication.getName();

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.AVAILABLE) {
            throw new RuntimeException("이미 신청되었거나 사용 중이거나 신청할 수 없는 사물함입니다.");
        }

        Locker updated = Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(Locker.Status.PENDING)
                .currentUserId(studentId)
                .assignedAt(null)
                .build();

        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, false);
    }

    // 신청 취소 (본인만) - PENDING -> AVAILABLE
    @PostMapping("/{id}/cancel")
    public LockerResponse cancelApplication(Authentication authentication, @PathVariable Long id) {
        String studentId = authentication.getName();

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.PENDING) {
            throw new RuntimeException("승인 대기 중인 신청이 아닙니다.");
        }

        if (!studentId.equals(locker.getCurrentUserId())) {
            throw new RuntimeException("본인이 신청한 건만 취소할 수 있습니다.");
        }

        Locker updated = resetLocker(locker, Locker.Status.AVAILABLE);
        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, false);
    }

    // 관리자 승인 (ADMIN만) - PENDING -> IN_USE
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public LockerResponse approveLocker(@PathVariable Long id) {
        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.PENDING) {
            throw new RuntimeException("승인 대기 중인 신청이 아닙니다.");
        }

        Locker updated = Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(Locker.Status.IN_USE)
                .currentUserId(locker.getCurrentUserId())
                .assignedAt(LocalDateTime.now())
                .build();

        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, true);
    }

    // 관리자 거부 (ADMIN만) - PENDING -> AVAILABLE
    @PostMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public LockerResponse rejectLocker(@PathVariable Long id) {
        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (locker.getStatus() != Locker.Status.PENDING) {
            throw new RuntimeException("승인 대기 중인 신청이 아닙니다.");
        }

        Locker updated = resetLocker(locker, Locker.Status.AVAILABLE);
        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, false);
    }

    // 사물함 반납 (본인 또는 ADMIN) - IN_USE -> AVAILABLE
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

        Locker updated = resetLocker(locker, Locker.Status.AVAILABLE);
        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, false);
    }

    // 사물함 상태 강제 변경 (ADMIN만) - 고장 처리 / 복구
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public LockerResponse updateStatus(@PathVariable Long id,
                                       @RequestParam Locker.Status status) {

        Locker locker = lockerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("사물함을 찾을 수 없습니다."));

        if (status == Locker.Status.IN_USE || status == Locker.Status.PENDING) {
            throw new RuntimeException("이 API로는 IN_USE/PENDING으로 직접 변경할 수 없습니다.");
        }

        Locker updated = resetLocker(locker, status);
        Locker saved = lockerRepository.save(updated);
        return LockerResponse.from(saved, true);
    }

    // 공용 헬퍼 - 사용자 정보를 초기화하며 상태만 바꿔 새 객체 생성
    private Locker resetLocker(Locker locker, Locker.Status newStatus) {
        return Locker.builder()
                .id(locker.getId())
                .lockerNumber(locker.getLockerNumber())
                .location(locker.getLocation())
                .password(locker.getPassword())
                .status(newStatus)
                .currentUserId(null)
                .assignedAt(null)
                .build();
    }
}