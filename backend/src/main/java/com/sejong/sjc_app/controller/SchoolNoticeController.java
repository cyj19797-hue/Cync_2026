package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.SchoolNotice;
import com.sejong.sjc_app.repository.SchoolNoticeRepository;
import com.sejong.sjc_app.service.SchoolNoticeCrawlerService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.sejong.sjc_app.service.EventDateRules;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/notices/school")
@RequiredArgsConstructor
public class SchoolNoticeController {

    private final SchoolNoticeRepository schoolNoticeRepository;
    private final SchoolNoticeCrawlerService crawlerService;

    @GetMapping
    public List<SchoolNotice> getNotices() {
        return schoolNoticeRepository.findAllByOrderByIsNoticeDescPostedDateDesc();
    }

    @PostMapping("/crawl")
    public String crawl() throws Exception {
        int count = crawlerService.crawlAndSave();
        return "새로 저장된 공지: " + count + "개";
    }

    // 관리자용 - 학과 공지의 안내 날짜 수동 지정 (기본은 모두 null)
    //  시작일만 보내면 하루, 둘 다 보내면 기간, 둘 다 안 보내면 날짜 삭제(null)
    @PutMapping("/{id}/event-date")
    @PreAuthorize("hasRole('ADMIN')")
    public SchoolNotice updateEventDate(@PathVariable Long id,
                                        @RequestParam(required = false) LocalDate eventStartDate,
                                        @RequestParam(required = false) LocalDate eventEndDate) {

        SchoolNotice notice = schoolNoticeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));

        LocalDate[] dates = EventDateRules.normalize(eventStartDate, eventEndDate);

        SchoolNotice updated = SchoolNotice.builder()
                .id(notice.getId())
                .articleNo(notice.getArticleNo())
                .title(notice.getTitle())
                .content(notice.getContent())
                .category(notice.getCategory())
                .isNotice(notice.isNotice())
                .postedDate(notice.getPostedDate())
                .viewCount(notice.getViewCount())
                .sourceUrl(notice.getSourceUrl())
                .crawledAt(notice.getCrawledAt())
                .eventStartDate(dates[0])
                .eventEndDate(dates[1])
                .build();

        return schoolNoticeRepository.save(updated);
    }

    @PostMapping("/backfill-content")
    @PreAuthorize("hasRole('ADMIN')")
    public String backfillContent() throws Exception {
        int count = crawlerService.backfillContent();
        return "본문 업데이트된 공지: " + count + "개";
    }
}