package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.Locker;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LockerRepository extends JpaRepository<Locker, Long> {
    List<Locker> findByStatus(Locker.Status status);
    Optional<Locker> findByLockerNumber(Integer lockerNumber);
    boolean existsByLockerNumber(Integer lockerNumber);
}