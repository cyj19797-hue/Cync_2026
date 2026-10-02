package com.sejong.sjc_app.dto;

import com.sejong.sjc_app.domain.Post;
import com.sejong.sjc_app.domain.User;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class PostResponse {
    private Long id;
    private String title;
    private String content;
    private String authorId;
    private String authorName;
    private String authorNickname;
    private User.ProfileColor authorColor;
    private boolean isAnonymous;
    private Integer viewCount;
    private Integer likeCount;
    private Integer commentCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private boolean likedByMe;

    public static PostResponse from(Post post, boolean likedByMe) {
        return PostResponse.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .authorId(post.getAuthorId())
                .authorName(post.getAuthorName())
                .authorNickname(post.getAuthorNickname())
                .authorColor(post.getAuthorColor())
                .isAnonymous(post.isAnonymous())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .commentCount(post.getCommentCount())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .likedByMe(likedByMe)
                .build();
    }
}