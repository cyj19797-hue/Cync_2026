package com.sejong.sjc_app.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TokenResponse {
    private String accessToken;
    private String tokenType;
    private SejongMemberInfo memberInfo;
}
