package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.service.WithdrawalService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me")
@RequiredArgsConstructor
public class AccountController {

    private final WithdrawalService withdrawalService;

    // 회원 탈퇴 (본인만)
    @DeleteMapping
    public String withdraw(Authentication authentication) {
        withdrawalService.withdraw(authentication.getName());
        return "탈퇴 완료";
    }
}