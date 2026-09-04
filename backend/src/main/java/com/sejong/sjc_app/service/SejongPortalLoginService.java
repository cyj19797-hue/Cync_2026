package com.sejong.sjc_app.service;

import com.sejong.sjc_app.dto.SejongMemberInfo;
import lombok.RequiredArgsConstructor;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.entity.UrlEncodedFormEntity;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.core5.http.message.BasicNameValuePair;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SejongPortalLoginService {

    private final SejongPortalAuthService authService;
    private final SejongMemberInfoParserService parserService;

    private static final String LOGIN_URL = "https://portal.sejong.ac.kr/jsp/login/login_action.jsp";
    private static final String SSO_URL = "http://classic.sejong.ac.kr/_custom/sejong/sso/sso-return.jsp?returnUrl=https://classic.sejong.ac.kr/classic/index.do";
    private static final String STATUS_URL = "https://classic.sejong.ac.kr/classic/reading/status.do";

    public SejongMemberInfo getMemberInfo(String id, String password) throws Exception {
        CloseableHttpClient client = authService.buildClient();

        // === 1단계: 포털 로그인 ===
        HttpPost loginRequest = new HttpPost(LOGIN_URL);
        // 3. 파라미터 수정: mainLogin, rtUrl, id, password
        loginRequest.setEntity(new UrlEncodedFormEntity(List.of(
                new BasicNameValuePair("mainLogin", "N"),
                new BasicNameValuePair("rtUrl", "library.sejong.ac.kr"),
                new BasicNameValuePair("id", id),
                new BasicNameValuePair("password", password)
        )));
        // 4. 키보드보안 끄기 쿠키 + 헤더
        loginRequest.setHeader("Referer", "https://portal.sejong.ac.kr");
        loginRequest.setHeader("Cookie", "chknos=false");

        client.execute(loginRequest, response -> {
            EntityUtils.consume(response.getEntity());
            return null;
        });

        // === 2단계: SSO 리다이렉트 (세션을 classic 도메인으로 넘김) ===
        HttpGet ssoRequest = new HttpGet(SSO_URL);
        client.execute(ssoRequest, response -> {
            EntityUtils.consume(response.getEntity());
            return null;
        });

        // === 3단계: 고전독서인증현황 페이지 크롤링 ===
        HttpGet statusRequest = new HttpGet(STATUS_URL);
        String html = client.execute(statusRequest, response ->
                EntityUtils.toString(response.getEntity())
        );

        // === 4단계: 파싱 ===
        return parserService.parseHTMLAndGetMemberInfo(html);
    }
}