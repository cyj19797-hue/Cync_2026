package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.AcademicSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AcademicScheduleRepository extends JpaRepository<AcademicSchedule, Long> {
    boolean existsByTitleAndStartDateAndSource(String title, java.time.LocalDate startDate, AcademicSchedule.Source source);
    List<AcademicSchedule> findAllByOrderByStartDateAsc();
}