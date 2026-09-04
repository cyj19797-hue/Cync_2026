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
import org.jsoup.nodes.TextNode;
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

    private static final List<String> BLOCK_TAGS =
            List.of("p", "div", "li", "h1", "h2", "h3", "h4", "h5", "h6");

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
                continue;
            }

            String title = titleLink.select("span").text().trim();
            String category = row.select("td").get(1).text().trim();
            boolean isNotice = row.select(".b-num-box .b-noti").size() > 0;
            String postedDate = row.select(".b-date").text().trim();
            String viewCountStr = row.select(".b-hit-box .b-hit").text().trim();
            Integer viewCount = viewCountStr.isEmpty() ? 0 : Integer.parseInt(viewCountStr);

            if (!isFromYearOrLater(postedDate, 2026)) {
                continue;
            }

            String href = titleLink.attr("href");
            String sourceUrl = NOTICE_URL + href;

            String content = extractContent(client, sourceUrl);

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

    // postedDate("2026.05.19" 형식)의 연도가 기준 연도 이상인지 확인
    private boolean isFromYearOrLater(String postedDate, int minYear) {
        try {
            String yearStr = postedDate.split("\\.")[0].trim();
            int year = Integer.parseInt(yearStr);
            return year >= minYear;
        } catch (Exception e) {
            return true; // 형식 파싱 실패 시 일단 저장 (방어적으로)
        }
    }

    public int backfillContent() throws Exception {
        CloseableHttpClient client = authService.buildClient();

        List<SchoolNotice> notices = schoolNoticeRepository.findAll();
        int updatedCount = 0;

        for (SchoolNotice notice : notices) {
            String content = extractContent(client, notice.getSourceUrl());

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

    private String extractContent(CloseableHttpClient client, String detailUrl) {
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

            for (Element br : contentBox.select("br")) {
                br.replaceWith(new TextNode(" @@BR@@ "));
            }

            StringBuilder result = new StringBuilder();
            appendBlockText(contentBox, result);

            String finalContent = result.toString();
            finalContent = finalContent.replace("@@BR@@", "\n");
            finalContent = finalContent.replaceAll("[ \\t]*\n[ \\t]*", "\n");
            finalContent = finalContent.replaceAll("\n{3,}", "\n\n");

            return finalContent.trim();

        } catch (Exception e) {
            return null;
        }
    }

    // 블록 태그를 만나면 그 텍스트만 추출하고 더 깊이 안 들어감 (자손 중복 방지)
    // 블록 태그가 아니거나, 안에 또 블록 태그가 있으면 자식으로 계속 내려감
    private void appendBlockText(Element element, StringBuilder result) {
        boolean isBlockTag = BLOCK_TAGS.contains(element.tagName());

        boolean hasBlockChild = element.children().stream()
                .anyMatch(child -> BLOCK_TAGS.contains(child.tagName()));

        if (isBlockTag && !hasBlockChild) {
            String line = element.text().trim();
            if (!line.isEmpty()) {
                result.append(line).append("\n");
            } else {
                result.append("\n");
            }
            return;
        }

        for (Element child : element.children()) {
            appendBlockText(child, result);
        }
    }

    @Scheduled(fixedRate = 10800000)
    public void scheduledCrawl() {
        try {
            int count = crawlAndSave();
            System.out.println("===== 자동 크롤링 완료: 새 공지 " + count + "개 =====");
        } catch (Exception e) {
            System.out.println("===== 자동 크롤링 실패: " + e.getMessage() + " =====");
        }
    }
}