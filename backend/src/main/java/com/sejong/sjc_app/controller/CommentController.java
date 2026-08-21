package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.Comment;
import com.sejong.sjc_app.domain.Post;
import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.repository.CommentRepository;
import com.sejong.sjc_app.repository.PostRepository;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class CommentController {

    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    // 댓글 목록 (누구나)
    @GetMapping("/api/posts/{postId}/comments")
    public List<Comment> getComments(@PathVariable Long postId) {
        return commentRepository.findByPostId(postId);
    }

    // 댓글 작성 (로그인 필요)
    @PostMapping("/api/posts/{postId}/comments")
    public Comment createComment(Authentication authentication,
                                 @PathVariable Long postId,
                                 @RequestParam String content,
                                 @RequestParam(required = false) Long parentCommentId,
                                 @RequestParam(required = false) String nickname,
                                 @RequestParam(required = false) User.ProfileColor color,
                                 @RequestParam(defaultValue = "false") boolean isAnonymous) {

        String studentId = authentication.getName();

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        if (parentCommentId != null) {
            Comment parent = commentRepository.findById(parentCommentId)
                    .orElseThrow(() -> new RuntimeException("답글 대상 댓글을 찾을 수 없습니다."));

            if (!parent.getPostId().equals(postId)) {
                throw new RuntimeException("다른 게시글의 댓글에는 답글을 달 수 없습니다.");
            }

            if (parent.getParentCommentId() != null) {
                throw new RuntimeException("답글에는 답글을 달 수 없습니다.");
            }
        }

        String finalNickname = (nickname != null) ? nickname : user.getNickname();
        User.ProfileColor finalColor = (color != null) ? color : user.getProfileColor();

        Comment comment = Comment.builder()
                .postId(postId)
                .parentCommentId(parentCommentId)
                .content(content)
                .authorId(studentId)
                .authorName(user.getName())
                .authorNickname(finalNickname)
                .authorColor(finalColor)
                .isAnonymous(isAnonymous)
                .createdAt(LocalDateTime.now())
                .build();

        Comment saved = commentRepository.save(comment);
        updatePostCommentCount(postId, 1);
        return saved;
    }

    // 댓글 삭제 (본인 or ADMIN) — 소프트 삭제
    @DeleteMapping("/api/comments/{id}")
    public String deleteComment(Authentication authentication, @PathVariable Long id) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("댓글을 찾을 수 없습니다."));

        String studentId = authentication.getName();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!comment.getAuthorId().equals(studentId) && !isAdmin) {
            throw new RuntimeException("본인 댓글만 삭제할 수 있습니다.");
        }

        Comment deleted = Comment.builder()
                .id(comment.getId())
                .postId(comment.getPostId())
                .parentCommentId(comment.getParentCommentId())
                .content("삭제된 댓글입니다")
                .authorId(comment.getAuthorId())
                .authorName(comment.getAuthorName())
                .authorNickname(comment.getAuthorNickname())
                .authorColor(comment.getAuthorColor())
                .isAnonymous(comment.isAnonymous())
                .isDeleted(true)
                .createdAt(comment.getCreatedAt())
                .build();

        commentRepository.save(deleted);
        return "삭제 완료";
    }

    // 게시글의 commentCount 증감
    private void updatePostCommentCount(Long postId, int delta) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        Post updated = Post.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .authorId(post.getAuthorId())
                .authorName(post.getAuthorName())
                .isAnonymous(post.isAnonymous())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .commentCount(post.getCommentCount() + delta)
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .build();

        postRepository.save(updated);
    }
}