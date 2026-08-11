package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.Comment;
import com.sejong.sjc_app.domain.Post;
import com.sejong.sjc_app.repository.CommentRepository;
import com.sejong.sjc_app.repository.PostRepository;
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

    // 특정 게시글의 댓글 목록 (누구나)
    @GetMapping("/api/posts/{postId}/comments")
    public List<Comment> getComments(@PathVariable Long postId) {
        return commentRepository.findByPostId(postId);
    }

    // 댓글 작성 (로그인 필요)
    @PostMapping("/api/posts/{postId}/comments")
    public Comment createComment(Authentication authentication,
                                 @PathVariable Long postId,
                                 @RequestParam String content,
                                 @RequestParam String authorName,
                                 @RequestParam(defaultValue = "false") boolean isAnonymous) {

        String studentId = authentication.getName();

        Comment comment = Comment.builder()
                .postId(postId)
                .content(content)
                .authorId(studentId)
                .authorName(authorName)
                .isAnonymous(isAnonymous)
                .createdAt(LocalDateTime.now())
                .build();

        Comment saved = commentRepository.save(comment);

        // 게시글 댓글수 +1
        updatePostCommentCount(postId, 1);

        return saved;
    }

    // 댓글 삭제 (본인 or ADMIN)
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

        commentRepository.deleteById(id);

        // 게시글 댓글수 -1
        updatePostCommentCount(comment.getPostId(), -1);

        return "삭제 완료";
    }

    // 게시글의 commentCount를 증감시키는 공통 메서드
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