package com.sejong.sjc_app.service;

import com.sejong.sjc_app.domain.SchoolNotice;
import com.sejong.sjc_app.repository.SchoolNoticeRepository;
import lombok.RequiredArgsConstructor;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SchoolNoticeCrawlerService {

    private final SchoolNoticeRepository schoolNoticeRepository;
    private final SejongPortalAuthService authService;

    private static final String NOTICE_URL = "https://dept.sejong.ac.kr/cedpt/board/notice.do";

    public int crawlAndSave() throws Exception {
        CloseableHttpClient client = authService.buildClient();

        HttpGet request = new HttpGet(NOTICE_URL);
        String html = client.execute(request, response ->
                EntityUtils.toString(response.getEntity())
        );

        Document doc = Jsoup.parse(html, NOTICE_URL);
        Elements rows = doc.select("tbody tr");

        int savedCount = 0;

        for (Element row : rows) {
            Element titleLink = row.selectFirst(".b-td-title a");
            if (titleLink == null) continue;

            String articleNoStr = titleLink.attr("data-article-no");
            if (articleNoStr.isEmpty()) continue;

            Long articleNo = Long.parseLong(articleNoStr);

            if (schoolNoticeRepository.findByArticleNo(articleNo).isPresent()) {
                continue;   // 중복 스킵
            }

            String title = titleLink.select("span").text().trim();
            String category = row.select("td").get(1).text().trim();
            boolean isNotice = row.select(".b-num-box .b-noti").size() > 0;
            String postedDate = row.select(".b-date").text().trim();
            String viewCountStr = row.select(".b-hit-box .b-hit").text().trim();
            Integer viewCount = viewCountStr.isEmpty() ? 0 : Integer.parseInt(viewCountStr);

            String href = titleLink.attr("href");
            String sourceUrl = NOTICE_URL + href;

            String content = fetchContent(client, sourceUrl);

            SchoolNotice notice = SchoolNotice.builder()
                    .articleNo(articleNo)
                    .title(title)
                    .content(content)
                    .category(category)
                    .isNotice(isNotice)
                    .postedDate(postedDate)
                    .viewCount(viewCount)
                    .sourceUrl(sourceUrl)
                    .crawledAt(LocalDateTime.now())
                    .build();

            schoolNoticeRepository.save(notice);
            savedCount++;
        }

        return savedCount;
    }

    // 이미 저장된 글 중 본문이 비어있는 것들을 찾아 채워 넣음
    public int backfillContent() throws Exception {
        CloseableHttpClient client = authService.buildClient();

        List<SchoolNotice> notices = schoolNoticeRepository.findAll();
        int updatedCount = 0;

        for (SchoolNotice notice : notices) {
            String content = fetchContent(client, notice.getSourceUrl());

            SchoolNotice updated = SchoolNotice.builder()
                    .id(notice.getId())
                    .articleNo(notice.getArticleNo())
                    .title(notice.getTitle())
                    .content(content)
                    .category(notice.getCategory())
                    .isNotice(notice.isNotice())
                    .postedDate(notice.getPostedDate())
                    .viewCount(notice.getViewCount())
                    .sourceUrl(notice.getSourceUrl())
                    .crawledAt(notice.getCrawledAt())
                    .build();

            schoolNoticeRepository.save(updated);
            updatedCount++;
        }

        return updatedCount;
    }

    private String fetchContent(CloseableHttpClient client, String detailUrl) {
        try {
            HttpGet detailRequest = new HttpGet(detailUrl);
            String detailHtml = client.execute(detailRequest, response ->
                    EntityUtils.toString(response.getEntity())
            );

            Document detailDoc = Jsoup.parse(detailHtml, detailUrl);
            Element contentBox = detailDoc.selectFirst(".b-content-box .fr-view");

            if (contentBox == null) {
                return null;
            }

            return contentBox.text().trim();
        } catch (Exception e) {
            return null;
        }
    }

    @Scheduled(fixedRate = 10800000) // 3시간마다
    public void scheduledCrawl() {
        try {
            int count = crawlAndSave();
            System.out.println("===== 자동 크롤링 완료: 새 공지 " + count + "개 =====");
        } catch (Exception e) {
            System.out.println("===== 자동 크롤링 실패: " + e.getMessage() + " =====");
        }
    }
}