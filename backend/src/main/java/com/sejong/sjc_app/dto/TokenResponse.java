package com.sejong.sjc_app.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TokenResponse {
    private String accessToken;
    private String tokenType;
    private SejongMemberInfo memberInfo;
    private boolean termsAgreed;   // false면 앱에서 약관 동의 화면을 먼저 보여줌
}
