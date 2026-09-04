package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.Report;
import com.sejong.sjc_app.repository.CommentRepository;
import com.sejong.sjc_app.repository.PostRepository;
import com.sejong.sjc_app.repository.ReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportRepository reportRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;

    // 신고하기 (로그인 필요)
    @PostMapping
    public Report createReport(Authentication authentication,
                               @RequestParam Report.TargetType targetType,
                               @RequestParam Long targetId,
                               @RequestParam Report.Reason reason,
                               @RequestParam(required = false) String detail) {

        String reporterId = authentication.getName();

        if (targetType == Report.TargetType.POST) {
            if (!postRepository.existsById(targetId)) {
                throw new RuntimeException("신고 대상 게시글을 찾을 수 없습니다.");
            }
        } else {
            if (!commentRepository.existsById(targetId)) {
                throw new RuntimeException("신고 대상 댓글을 찾을 수 없습니다.");
            }
        }

        boolean alreadyReported = reportRepository
                .existsByTargetTypeAndTargetIdAndReporterId(targetType, targetId, reporterId);

        if (alreadyReported) {
            throw new RuntimeException("이미 신고한 게시물입니다.");
        }

        Report report = Report.builder()
                .targetType(targetType)
                .targetId(targetId)
                .reporterId(reporterId)
                .reason(reason)
                .detail(detail)
                .status(Report.Status.PENDING)
                .createdAt(LocalDateTime.now())
                .build();

        return reportRepository.save(report);
    }

    // 신고 목록 조회 - 미처리 건만 (ADMIN만)
    @GetMapping("/pending")
    @PreAuthorize("hasRole('ADMIN')")
    public List<Report> getPendingReports() {
        return reportRepository.findByStatusOrderByCreatedAtDesc(Report.Status.PENDING);
    }

    // 신고 목록 전체 조회 (ADMIN만)
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public List<Report> getAllReports() {
        return reportRepository.findAllByOrderByCreatedAtDesc();
    }

    // 신고 처리 완료 표시 (ADMIN만)
    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public Report resolveReport(@PathVariable Long id) {
        Report report = reportRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("신고 내역을 찾을 수 없습니다."));

        Report updated = Report.builder()
                .id(report.getId())
                .targetType(report.getTargetType())
                .targetId(report.getTargetId())
                .reporterId(report.getReporterId())
                .reason(report.getReason())
                .detail(report.getDetail())
                .status(Report.Status.RESOLVED)
                .createdAt(report.getCreatedAt())
                .build();

        return reportRepository.save(updated);
    }
}