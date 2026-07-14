package com.bookstore.couponfeedback.service;

import com.bookstore.couponfeedback.dto.request.FeedbackRequest;
import com.bookstore.couponfeedback.dto.response.ApiResponse;
import com.bookstore.couponfeedback.entity.Feedback;
import com.bookstore.couponfeedback.repository.FeedbackRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Instant;

@Slf4j
@Service
@RequiredArgsConstructor
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;

    public ApiResponse<Page<Feedback>> getAllFeedbacks(int page, int size) {
        return ApiResponse.success("OK", feedbackRepository.findAll(PageRequest.of(page, size)));
    }

    public ApiResponse<Long> getUnreadCount() {
        return ApiResponse.success("OK", feedbackRepository.countByReadFalse());
    }

    public ApiResponse<Feedback> addFeedback(int userId, FeedbackRequest request) {
        Feedback feedback = Feedback.builder()
                .content(request.getContent())
                .userId(userId)
                .read(false)
                .createdAt(Timestamp.from(Instant.now()))
                .build();
        return ApiResponse.success("Gửi phản hồi thành công!", feedbackRepository.save(feedback));
    }

    public ApiResponse<Feedback> markAsRead(long id) {
        Feedback feedback = feedbackRepository.findById(id).orElse(null);
        if (feedback == null) return ApiResponse.error("Phản hồi không tồn tại!");
        feedback.setRead(true);
        return ApiResponse.success("Đã đánh dấu đọc!", feedbackRepository.save(feedback));
    }

    public ApiResponse<Void> deleteFeedback(long id) {
        if (!feedbackRepository.existsById(id)) return ApiResponse.error("Phản hồi không tồn tại!");
        feedbackRepository.deleteById(id);
        return ApiResponse.success("Xóa phản hồi thành công!");
    }
}
