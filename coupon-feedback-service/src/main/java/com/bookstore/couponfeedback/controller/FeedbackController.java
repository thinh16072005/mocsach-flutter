package com.bookstore.couponfeedback.controller;

import com.bookstore.couponfeedback.dto.request.FeedbackRequest;
import com.bookstore.couponfeedback.dto.response.ApiResponse;
import com.bookstore.couponfeedback.entity.Feedback;
import com.bookstore.couponfeedback.service.FeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/feedbacks")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<Feedback>>> getAllFeedbacks(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(feedbackService.getAllFeedbacks(page, size));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount() {
        return ResponseEntity.ok(feedbackService.getUnreadCount());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Feedback>> addFeedback(
            @RequestHeader(value = "X-User-Id", defaultValue = "0") int userId,
            @RequestBody FeedbackRequest request) {
        return ResponseEntity.ok(feedbackService.addFeedback(userId, request));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Feedback>> markAsRead(@PathVariable long id) {
        ApiResponse<Feedback> response = feedbackService.markAsRead(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteFeedback(@PathVariable long id) {
        ApiResponse<Void> response = feedbackService.deleteFeedback(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
