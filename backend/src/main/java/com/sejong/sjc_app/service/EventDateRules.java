package com.sejong.sjc_app.service;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;

// 안내사항 날짜 검증/정규화
//  - 둘 다 없음  -> 날짜 없음
//  - 시작일만    -> 하루 (종료일 = 시작일)
//  - 둘 다 있음  -> 기간 (종료일은 시작일보다 빠를 수 없음)
//  - 종료일만    -> 오류(400)
public final class EventDateRules {

    private EventDateRules() {}

    // 반환: [시작일, 종료일]
    public static LocalDate[] normalize(LocalDate start, LocalDate end) {
        if (start == null && end == null) {
            return new LocalDate[]{null, null};
        }
        if (start == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "종료일만 지정할 수 없습니다. 시작일을 함께 입력하세요.");
        }
        LocalDate realEnd = (end != null) ? end : start;
        if (realEnd.isBefore(start)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "종료일은 시작일보다 빠를 수 없습니다.");
        }
        return new LocalDate[]{start, realEnd};
    }
}
