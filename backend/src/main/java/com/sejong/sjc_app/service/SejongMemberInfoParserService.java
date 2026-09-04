package com.sejong.sjc_app.service;

import com.sejong.sjc_app.dto.SejongMemberInfo;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

@Service
public class SejongMemberInfoParserService {

    public SejongMemberInfo parseHTMLAndGetMemberInfo(String html) {
        Document doc = Jsoup.parse(html);

        String selector = ".b-con-box:has(h4.b-h4-tit01:contains(사용자 정보)) table.b-board-table tbody tr";
        List<String> rowValues = new ArrayList<>();

        doc.select(selector).forEach(tr -> {
            String value = tr.select("td").text().trim();
            rowValues.add(value);
        });

        return SejongMemberInfo.builder()
                .major(getValueFromList(rowValues, 0))
                .studentId(getValueFromList(rowValues, 1))
                .name(getValueFromList(rowValues, 2))
                .grade(getValueFromList(rowValues, 3))
                .status(getValueFromList(rowValues, 4))
                .completedSemester(getValueFromList(rowValues, 5))
                .build();
    }

    private String getValueFromList(List<String> list, int index) {
        return list.size() > index ? list.get(index) : null;
    }
}