package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.StudentCouncilNotice;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentCouncilNoticeRepository extends JpaRepository<StudentCouncilNotice, Long> {
}