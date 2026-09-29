package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.SchoolNotice;
import com.sejong.sjc_app.repository.SchoolNoticeRepository;
import com.sejong.sjc_app.service.SchoolNoticeCrawlerService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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

    @PostMapping("/backfill-content")
    @PreAuthorize("hasRole('ADMIN')")
    public String backfillContent() throws Exception {
        int count = crawlerService.backfillContent();
        return "본문 업데이트된 공지: " + count + "개";
    }
}