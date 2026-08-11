package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.StudentCouncilNotice;
import com.sejong.sjc_app.repository.StudentCouncilNoticeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/notices/council")
@RequiredArgsConstructor
public class StudentCouncilNoticeController {

    private final StudentCouncilNoticeRepository repository;

    // 목록 조회 (누구나 가능)
    @GetMapping
    public List<StudentCouncilNotice> getNotices() {
        return repository.findAll();
    }

    // 상세 조회 (누구나 가능)
    @GetMapping("/{id}")
    public StudentCouncilNotice getNotice(@PathVariable Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));
    }

    // 작성 (ADMIN만)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public StudentCouncilNotice createNotice(@RequestParam String title,
                                             @RequestParam String content,
                                             @RequestParam String authorId,
                                             @RequestParam String authorName) {
        StudentCouncilNotice notice = StudentCouncilNotice.builder()
                .title(title)
                .content(content)
                .authorId(authorId)
                .authorName(authorName)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        return repository.save(notice);
    }

    // 수정 (ADMIN만)
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public StudentCouncilNotice updateNotice(@PathVariable Long id,
                                             @RequestParam String title,
                                             @RequestParam String content) {
        StudentCouncilNotice notice = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));

        StudentCouncilNotice updated = StudentCouncilNotice.builder()
                .id(notice.getId())
                .title(title)
                .content(content)
                .authorId(notice.getAuthorId())
                .authorName(notice.getAuthorName())
                .createdAt(notice.getCreatedAt())
                .updatedAt(LocalDateTime.now())
                .build();

        return repository.save(updated);
    }

    // 삭제 (ADMIN만)
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteNotice(@PathVariable Long id) {
        repository.deleteById(id);
        return "삭제 완료";
    }
}