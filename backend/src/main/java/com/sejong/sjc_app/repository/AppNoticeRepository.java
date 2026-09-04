package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.AppNotice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AppNoticeRepository extends JpaRepository<AppNotice, Long> {
    List<AppNotice> findByIsPopupTrue();
    List<AppNotice> findAllByOrderByCreatedAtDesc();
}