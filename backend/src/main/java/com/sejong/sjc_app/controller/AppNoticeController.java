package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.AppNotice;
import com.sejong.sjc_app.repository.AppNoticeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/app-notices")
@RequiredArgsConstructor
public class AppNoticeController {

    private final AppNoticeRepository appNoticeRepository;

    // 전체 공지 목록 (설정 메뉴에서 조회, 누구나)
    @GetMapping
    public List<AppNotice> getNotices() {
        return appNoticeRepository.findAllByOrderByCreatedAtDesc();
    }

    // 지금 띄워야 할 팝업 공지 목록 (앱 켤 때 호출, 누구나)
    @GetMapping("/popup")
    public List<AppNotice> getPopupNotices() {
        return appNoticeRepository.findByIsPopupTrue();
    }

    // 작성 (ADMIN만)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public AppNotice createNotice(Authentication authentication,
                                  @RequestParam String title,
                                  @RequestParam String content,
                                  @RequestParam(defaultValue = "false") boolean isPopup) {

        String studentId = authentication.getName();

        AppNotice notice = AppNotice.builder()
                .title(title)
                .content(content)
                .isPopup(isPopup)
                .authorId(studentId)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        return appNoticeRepository.save(notice);
    }

    // 수정 (ADMIN만)
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public AppNotice updateNotice(@PathVariable Long id,
                                  @RequestParam String title,
                                  @RequestParam String content,
                                  @RequestParam(defaultValue = "false") boolean isPopup) {

        AppNotice notice = appNoticeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));

        AppNotice updated = AppNotice.builder()
                .id(notice.getId())
                .title(title)
                .content(content)
                .isPopup(isPopup)
                .authorId(notice.getAuthorId())
                .createdAt(notice.getCreatedAt())
                .updatedAt(LocalDateTime.now())
                .build();

        return appNoticeRepository.save(updated);
    }

    // 삭제 (ADMIN만)
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteNotice(@PathVariable Long id) {
        appNoticeRepository.deleteById(id);
        return "삭제 완료";
    }
}