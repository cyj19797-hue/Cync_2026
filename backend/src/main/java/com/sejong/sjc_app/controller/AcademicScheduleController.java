package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.AcademicSchedule;
import com.sejong.sjc_app.repository.AcademicScheduleRepository;
import com.sejong.sjc_app.service.AcademicScheduleCrawlerService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/academic-schedule")
@RequiredArgsConstructor
public class AcademicScheduleController {

    private final AcademicScheduleRepository academicScheduleRepository;
    private final AcademicScheduleCrawlerService crawlerService;

    // 전체 일정 조회 (누구나, 학교+학생회 통합, 날짜순)
    @GetMapping
    public List<AcademicSchedule> getSchedules() {
        return academicScheduleRepository.findAllByOrderByStartDateAsc();
    }

    // 수동 크롤링 트리거 (ADMIN만)
    @PostMapping("/crawl")
    @PreAuthorize("hasRole('ADMIN')")
    public String crawl(@RequestParam int year) throws Exception {
        int count = crawlerService.crawlAndSave(year);
        return "새로 저장된 일정: " + count + "개";
    }

    // 학생회 일정 추가 (ADMIN만)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public AcademicSchedule createSchedule(Authentication authentication,
                                           @RequestParam String title,
                                           @RequestParam LocalDate startDate,
                                           @RequestParam LocalDate endDate) {

        String studentId = authentication.getName();

        AcademicSchedule schedule = AcademicSchedule.builder()
                .title(title)
                .startDate(startDate)
                .endDate(endDate)
                .source(AcademicSchedule.Source.STUDENT_COUNCIL)
                .authorId(studentId)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        return academicScheduleRepository.save(schedule);
    }

    // 학생회 일정 수정 (ADMIN만)
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public AcademicSchedule updateSchedule(@PathVariable Long id,
                                           @RequestParam String title,
                                           @RequestParam LocalDate startDate,
                                           @RequestParam LocalDate endDate) {

        AcademicSchedule schedule = academicScheduleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("일정을 찾을 수 없습니다."));

        if (schedule.getSource() != AcademicSchedule.Source.STUDENT_COUNCIL) {
            throw new RuntimeException("학교 공식 일정은 수정할 수 없습니다.");
        }

        AcademicSchedule updated = AcademicSchedule.builder()
                .id(schedule.getId())
                .title(title)
                .startDate(startDate)
                .endDate(endDate)
                .source(schedule.getSource())
                .authorId(schedule.getAuthorId())
                .createdAt(schedule.getCreatedAt())
                .updatedAt(LocalDateTime.now())
                .build();

        return academicScheduleRepository.save(updated);
    }

    // 학생회 일정 삭제 (ADMIN만)
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteSchedule(@PathVariable Long id) {
        AcademicSchedule schedule = academicScheduleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("일정을 찾을 수 없습니다."));

        if (schedule.getSource() != AcademicSchedule.Source.STUDENT_COUNCIL) {
            throw new RuntimeException("학교 공식 일정은 삭제할 수 없습니다.");
        }

        academicScheduleRepository.deleteById(id);
        return "삭제 완료";
    }
}