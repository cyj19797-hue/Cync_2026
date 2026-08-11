package com.sejong.sjc_app.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class SejongMemberInfo {
    private String major;
    private String studentId;
    private String name;
    private String grade;
    private String status;
    private String completedSemester;
}