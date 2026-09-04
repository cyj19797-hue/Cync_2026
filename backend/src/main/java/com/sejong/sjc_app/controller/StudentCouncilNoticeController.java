package com.sejong.sjc_app.controller;

import com.sejong.sjc_app.domain.StudentCouncilNotice;
import com.sejong.sjc_app.repository.StudentCouncilNoticeRepository;
import com.sejong.sjc_app.service.AzureBlobStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/notices/council")
@RequiredArgsConstructor
public class StudentCouncilNoticeController {

    private final StudentCouncilNoticeRepository repository;
    private final AzureBlobStorageService azureBlobStorageService;

    @GetMapping
    public List<StudentCouncilNotice> getNotices() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public StudentCouncilNotice getNotice(@PathVariable Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public StudentCouncilNotice createNotice(@RequestParam String title,
                                             @RequestParam String content,
                                             @RequestParam String authorId,
                                             @RequestParam String authorName,
                                             @RequestParam(required = false) MultipartFile image) throws IOException {

        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = azureBlobStorageService.uploadImage(image);
        }

        StudentCouncilNotice notice = StudentCouncilNotice.builder()
                .title(title)
                .content(content)
                .imageUrl(imageUrl)
                .authorId(authorId)
                .authorName(authorName)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        return repository.save(notice);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public StudentCouncilNotice updateNotice(@PathVariable Long id,
                                             @RequestParam String title,
                                             @RequestParam String content,
                                             @RequestParam(required = false) MultipartFile image) throws IOException {

        StudentCouncilNotice notice = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("공지를 찾을 수 없습니다."));

        String imageUrl = notice.getImageUrl();
        if (image != null && !image.isEmpty()) {
            imageUrl = azureBlobStorageService.uploadImage(image);
        }

        StudentCouncilNotice updated = StudentCouncilNotice.builder()
                .id(notice.getId())
                .title(title)
                .content(content)
                .imageUrl(imageUrl)
                .authorId(notice.getAuthorId())
                .authorName(notice.getAuthorName())
                .createdAt(notice.getCreatedAt())
                .updatedAt(LocalDateTime.now())
                .build();

        return repository.save(updated);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteNotice(@PathVariable Long id) {
        repository.deleteById(id);
        return "삭제 완료";
    }
}