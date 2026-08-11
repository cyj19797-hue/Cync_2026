package com.sejong.sjc_app.service;

import org.apache.hc.client5.http.cookie.BasicCookieStore;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManagerBuilder;
import org.apache.hc.client5.http.ssl.NoopHostnameVerifier;
import org.apache.hc.client5.http.ssl.SSLConnectionSocketFactory;
import org.apache.hc.core5.ssl.SSLContextBuilder;
import org.springframework.stereotype.Service;

import javax.net.ssl.SSLContext;

@Service
public class SejongPortalAuthService {

    public CloseableHttpClient buildClient() throws Exception {
        SSLContext sslContext = SSLContextBuilder.create()
                .loadTrustMaterial(null, (chain, authType) -> true)
                .build();

        SSLConnectionSocketFactory sslSocketFactory = new SSLConnectionSocketFactory(
                sslContext,
                new String[]{"TLSv1.2"},
                new String[]{"TLS_RSA_WITH_AES_256_CBC_SHA"},
                NoopHostnameVerifier.INSTANCE
        );

        var connectionManager = PoolingHttpClientConnectionManagerBuilder.create()
                .setSSLSocketFactory(sslSocketFactory)
                .build();

        return HttpClients.custom()
                .setConnectionManager(connectionManager)
                .setDefaultCookieStore(new BasicCookieStore())  // 쿠키 자동 저장/전송
                .build();
    }
}