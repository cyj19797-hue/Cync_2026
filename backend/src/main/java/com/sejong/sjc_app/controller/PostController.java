package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.Post;
import com.sejong.sjc_app.domain.PostLike;
import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.repository.PostLikeRepository;
import com.sejong.sjc_app.repository.PostRepository;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostRepository postRepository;
    private final PostLikeRepository postLikeRepository;
    private final UserRepository userRepository;

    // 목록 조회 (누구나)
    @GetMapping
    public List<Post> getPosts() {
        return postRepository.findAll();
    }

    // 상세 조회 + 조회수 증가 (누구나)
    @GetMapping("/{id}")
    public Post getPost(@PathVariable Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        Post updated = Post.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .authorId(post.getAuthorId())
                .authorName(post.getAuthorName())
                .isAnonymous(post.isAnonymous())
                .viewCount(post.getViewCount() + 1)
                .likeCount(post.getLikeCount())
                .commentCount(post.getCommentCount())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .build();

        return postRepository.save(updated);
    }

    // 작성 (로그인 필요)
    @PostMapping
    public Post createPost(Authentication authentication,
                           @RequestParam String title,
                           @RequestParam String content,
                           @RequestParam(required = false) String nickname,
                           @RequestParam(required = false) User.ProfileColor color,
                           @RequestParam(defaultValue = "false") boolean isAnonymous) {

        String studentId = authentication.getName();

        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        String finalNickname = (nickname != null) ? nickname : user.getNickname();
        User.ProfileColor finalColor = (color != null) ? color : user.getProfileColor();

        Post post = Post.builder()
                .title(title)
                .content(content)
                .authorId(studentId)
                .authorName(user.getName())
                .authorNickname(finalNickname)
                .authorColor(finalColor)
                .isAnonymous(isAnonymous)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        return postRepository.save(post);
    }

    // 수정 (본인만)
    @PutMapping("/{id}")
    public Post updatePost(Authentication authentication,
                           @PathVariable Long id,
                           @RequestParam String title,
                           @RequestParam String content) {

        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        String studentId = authentication.getName();
        if (!post.getAuthorId().equals(studentId)) {
            throw new RuntimeException("본인 게시글만 수정할 수 있습니다.");
        }

        Post updated = Post.builder()
                .id(post.getId())
                .title(title)
                .content(content)
                .authorId(post.getAuthorId())
                .authorName(post.getAuthorName())
                .isAnonymous(post.isAnonymous())
                .viewCount(post.getViewCount())
                .likeCount(post.getLikeCount())
                .commentCount(post.getCommentCount())
                .createdAt(post.getCreatedAt())
                .updatedAt(LocalDateTime.now())
                .build();

        return postRepository.save(updated);
    }

    // 삭제 (본인 or ADMIN)
    @DeleteMapping("/{id}")
    public String deletePost(Authentication authentication, @PathVariable Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        String studentId = authentication.getName();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!post.getAuthorId().equals(studentId) && !isAdmin) {
            throw new RuntimeException("본인 게시글만 삭제할 수 있습니다.");
        }

        postRepository.deleteById(id);
        return "삭제 완료";
    }

    // 좋아요 토글 (로그인 필요)
    @PostMapping("/{id}/like")
    public String toggleLike(Authentication authentication, @PathVariable Long id) {
        String studentId = authentication.getName();

        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("게시글을 찾을 수 없습니다."));

        var existingLike = postLikeRepository.findByPostIdAndStudentId(id, studentId);

        if (existingLike.isPresent()) {
            // 이미 눌렀으면 취소
            postLikeRepository.delete(existingLike.get());
            savePostWithLikeCount(post, post.getLikeCount() - 1);
            return "좋아요 취소";
        } else {
            // 안 눌렀으면 추가
            postLikeRepository.save(PostLike.builder()
                    .postId(id)
                    .studentId(studentId)
                    .build());
            savePostWithLikeCount(post, post.getLikeCount() + 1);
            return "좋아요 완료";
        }
    }

    private void savePostWithLikeCount(Post post, int newLikeCount) {
        Post updated = Post.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .authorId(post.getAuthorId())
                .authorName(post.getAuthorName())
                .isAnonymous(post.isAnonymous())
                .viewCount(post.getViewCount())
                .likeCount(newLikeCount)
                .commentCount(post.getCommentCount())
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .build();
        postRepository.save(updated);
    }
}