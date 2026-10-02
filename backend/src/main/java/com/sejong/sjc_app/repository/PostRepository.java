package com.sejong.sjc_app.repository;

import com.sejong.sjc_app.domain.Post;
import com.sejong.sjc_app.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PostRepository extends JpaRepository<Post, Long> {

    @Modifying(clearAutomatically = true)
    @Query("update Post p set p.authorId = :newId, p.authorName = :label, p.authorNickname = :label, p.authorColor = :color where p.authorId = :oldId")
    int anonymizeAuthor(@Param("oldId") String oldId, @Param("newId") String newId,
                        @Param("label") String label, @Param("color") User.ProfileColor color);

    @Modifying(clearAutomatically = true)
    @Query("update Post p set p.likeCount = p.likeCount - 1 where p.id = :id and p.likeCount > 0")
    int decrementLikeCount(@Param("id") Long id);
}