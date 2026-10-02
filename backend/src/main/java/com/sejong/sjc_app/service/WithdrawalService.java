package com.sejong.sjc_app.service;

import com.sejong.sjc_app.domain.PostLike;
import com.sejong.sjc_app.domain.User;
import com.sejong.sjc_app.repository.CommentRepository;
import com.sejong.sjc_app.repository.LockerRepository;
import com.sejong.sjc_app.repository.PostLikeRepository;
import com.sejong.sjc_app.repository.PostRepository;
import com.sejong.sjc_app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WithdrawalService {

    private static final String WITHDRAWN_LABEL = "탈퇴한 사용자";
    private static final String WITHDRAWN_ID = "WITHDRAWN";

    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final PostLikeRepository postLikeRepository;
    private final LockerRepository lockerRepository;

    @Transactional
    public void withdraw(String studentId) {
        User user = userRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        if (user.isWithdrawn()) {
            throw new RuntimeException("이미 탈퇴한 계정입니다.");
        }

        if (lockerRepository.existsByCurrentUserId(studentId)) {
            throw new RuntimeException("사용 중이거나 신청 중인 사물함이 있어 탈퇴할 수 없습니다. 사물함을 먼저 반납하거나 신청을 취소해주세요.");
        }

        // 좋아요 정리: 글의 좋아요 수를 먼저 줄이고 기록을 삭제
        for (PostLike like : postLikeRepository.findByStudentId(studentId)) {
            postRepository.decrementLikeCount(like.getPostId());
        }
        postLikeRepository.deleteByStudentId(studentId);

        // 글/댓글은 남기되 작성자 정보를 지움
        postRepository.anonymizeAuthor(studentId, WITHDRAWN_ID, WITHDRAWN_LABEL, User.ProfileColor.GRAY);
        commentRepository.anonymizeAuthor(studentId, WITHDRAWN_ID, WITHDRAWN_LABEL, User.ProfileColor.GRAY);

        userRepository.save(user.withdraw());
    }
}