package com.sejong.sjc_app.service;

import com.sejong.sjc_app.domain.AcademicSchedule;
import com.sejong.sjc_app.repository.AcademicScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AcademicScheduleCrawlerService {

    private final AcademicScheduleRepository academicScheduleRepository;

    private static final String CALENDAR_URL_BASE =
            "https://www.sejong.ac.kr/kor/academics/academic-calendar.do?mode=list&selectedYear=";

    private static final Pattern MONTH_PATTERN = Pattern.compile("(?:(\\d{4})년\\s*)?(\\d{1,2})월");

    public int crawlAndSave(int year) throws Exception {
        String url = CALENDAR_URL_BASE + year;

        Document doc = Jsoup.connect(url)
                .userAgent("Mozilla/5.0")
                .get();

        Elements monthWraps = doc.select(".b-calendar-annual .b-month-wrap");

        int savedCount = 0;

        for (Element monthWrap : monthWraps) {
            String monthTitleText = monthWrap.select(".b-month-title p").text().trim();

            int resolvedYear = year;
            int month;

            Matcher matcher = MONTH_PATTERN.matcher(monthTitleText);
            if (!matcher.find()) {
                continue;
            }
            if (matcher.group(1) != null) {
                resolvedYear = Integer.parseInt(matcher.group(1));
            }
            month = Integer.parseInt(matcher.group(2));

            Elements items = monthWrap.select(".b-schedule-item");

            for (Element item : items) {
                String dateText = item.select(".b-schedule-date").text().trim();
                String content = item.select(".b-schedule-content").text().trim();

                if (dateText.isEmpty() || content.isEmpty()) {
                    continue;
                }

                LocalDate[] parsedDates = parseDateRange(dateText, resolvedYear, month);
                if (parsedDates == null) {
                    continue;
                }

                LocalDate startDate = parsedDates[0];
                LocalDate endDate = parsedDates[1];

                boolean alreadyExists = academicScheduleRepository
                        .existsByTitleAndStartDateAndSource(content, startDate, AcademicSchedule.Source.SCHOOL);

                if (alreadyExists) {
                    continue;
                }

                AcademicSchedule schedule = AcademicSchedule.builder()
                        .title(content)
                        .startDate(startDate)
                        .endDate(endDate)
                        .source(AcademicSchedule.Source.SCHOOL)
                        .createdAt(LocalDateTime.now())
                        .updatedAt(LocalDateTime.now())
                        .build();

                academicScheduleRepository.save(schedule);
                savedCount++;
            }
        }

        return savedCount;
    }

    private LocalDate[] parseDateRange(String dateText, int fallbackYear, int fallbackMonth) {
        String[] parts = dateText.split("~");

        LocalDate start = parseSingleDate(parts[0].trim(), fallbackYear, fallbackMonth);
        if (start == null) {
            return null;
        }

        LocalDate end = (parts.length > 1)
                ? parseSingleDate(parts[1].trim(), fallbackYear, fallbackMonth)
                : start;

        if (end == null) {
            end = start;
        }

        return new LocalDate[]{start, end};
    }

    private LocalDate parseSingleDate(String text, int fallbackYear, int fallbackMonth) {
        String[] tokens = text.split("\\.");
        if (tokens.length < 2) {
            return null;
        }

        try {
            int month = Integer.parseInt(tokens[0].trim());
            int day = Integer.parseInt(tokens[1].trim());

            int year = fallbackYear;
            if (month < fallbackMonth) {
                year = fallbackYear + 1;
            }

            return LocalDate.of(year, month, day);
        } catch (Exception e) {
            return null;
        }
    }
}