package com.sejong.sjc_app.service;

import com.sejong.sjc_app.domain.Locker;
import com.sejong.sjc_app.repository.LockerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LockerExpiryService {

    private final LockerRepository lockerRepository;

    @Scheduled(fixedRate = 3600000) // 1시간마다
    public void releaseExpiredLockers() {
        List<Locker> inUseLockers = lockerRepository.findByStatus(Locker.Status.IN_USE);

        LocalDateTime now = LocalDateTime.now();
        int releasedCount = 0;

        for (Locker locker : inUseLockers) {
            if (locker.getDueDate() != null && locker.getDueDate().isBefore(now)) {
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

                lockerRepository.save(released);
                releasedCount++;
            }
        }

        if (releasedCount > 0) {
            System.out.println("===== 사물함 자동 반납 처리: " + releasedCount + "건 =====");
        }
    }
}