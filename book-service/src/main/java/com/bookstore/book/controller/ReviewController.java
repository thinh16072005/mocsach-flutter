package com.bookstore.book.controller;

import com.bookstore.book.dto.request.ReviewRequest;
import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.entity.Review;
import com.bookstore.book.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @GetMapping("/book/{bookId}")
    public ResponseEntity<ApiResponse<List<Review>>> getReviewsByBook(@PathVariable int bookId) {
        return ResponseEntity.ok(reviewService.getReviewsByBook(bookId));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Review>> addReview(
            @RequestHeader("X-User-Id") int userId,
            @RequestBody ReviewRequest request) {
        ApiResponse<Review> response = reviewService.addReview(userId, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
