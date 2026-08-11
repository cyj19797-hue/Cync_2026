package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, String> {
}