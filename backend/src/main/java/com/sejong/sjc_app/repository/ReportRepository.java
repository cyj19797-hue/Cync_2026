package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.Report;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReportRepository extends JpaRepository<Report, Long> {
    boolean existsByTargetTypeAndTargetIdAndReporterId(Report.TargetType targetType, Long targetId, String reporterId);
    List<Report> findByStatusOrderByCreatedAtDesc(Report.Status status);
    List<Report> findAllByOrderByCreatedAtDesc();
}