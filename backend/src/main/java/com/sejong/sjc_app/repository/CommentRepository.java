package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.Comment;
import com.sejong.sjc_app.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    List<Comment> findByPostId(Long postId);

    @Modifying(clearAutomatically = true)
    @Query("update Comment c set c.authorId = :newId, c.authorName = :label, c.authorNickname = :label, c.authorColor = :color where c.authorId = :oldId")
    int anonymizeAuthor(@Param("oldId") String oldId, @Param("newId") String newId,
                        @Param("label") String label, @Param("color") User.ProfileColor color);
}