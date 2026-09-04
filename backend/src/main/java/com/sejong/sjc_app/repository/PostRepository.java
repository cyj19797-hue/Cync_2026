package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.Post;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Long> {
}