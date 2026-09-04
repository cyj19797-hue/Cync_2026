package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.SchoolNotice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SchoolNoticeRepository extends JpaRepository<SchoolNotice, Long> {

    Optional<SchoolNotice> findByArticleNo(Long articleNo);
}