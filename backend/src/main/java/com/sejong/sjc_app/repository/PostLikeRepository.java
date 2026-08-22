package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PostLikeRepository extends JpaRepository<PostLike, Long> {
    Optional<PostLike> findByPostIdAndStudentId(Long postId, String studentId);
    void deleteByPostId(Long postId);
}