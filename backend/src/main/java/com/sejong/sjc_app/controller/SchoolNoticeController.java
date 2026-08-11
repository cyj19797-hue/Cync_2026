package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.SchoolNotice;
import com.sejong.sjc_app.repository.SchoolNoticeRepository;
import com.sejong.sjc_app.service.SchoolNoticeCrawlerService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notices/school")
@RequiredArgsConstructor
public class SchoolNoticeController {

    private final SchoolNoticeRepository schoolNoticeRepository;
    private final SchoolNoticeCrawlerService crawlerService;

    // 학과 공지 목록 조회 (최신순)
    @GetMapping
    public List<SchoolNotice> getNotices() {
        return schoolNoticeRepository.findAll();
    }

    // 수동으로 크롤링 실행 (테스트용)
    @PostMapping("/crawl")
    public String crawl() throws Exception {
        int count = crawlerService.crawlAndSave();
        return "새로 저장된 공지: " + count + "개";
    }
}