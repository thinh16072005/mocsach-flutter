package com.bookstore.book.service;

import com.bookstore.book.dto.request.ReviewRequest;
import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.entity.Book;
import com.bookstore.book.entity.Review;
import com.bookstore.book.repository.BookRepository;
import com.bookstore.book.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookRepository bookRepository;

    public ApiResponse<List<Review>> getReviewsByBook(int bookId) {
        return ApiResponse.success("OK", reviewRepository.findByBookId(bookId));
    }

    public ApiResponse<Review> addReview(int userId, ReviewRequest request) {
        Book book = bookRepository.findById(request.getBookId()).orElse(null);
        if (book == null) return ApiResponse.error("Sách không tồn tại!");

        Review review = Review.builder()
                .bookId(request.getBookId())
                .userId(userId)
                .content(request.getContent())
                .ratingPoint(request.getRatingPoint())
                .orderDetailId(request.getOrderDetailId())
                .timestamp(Timestamp.from(Instant.now()))
                .build();
        review = reviewRepository.save(review);

        // Cập nhật avgRating cho sách
        updateBookAvgRating(request.getBookId());
        return ApiResponse.success("Đánh giá thành công!", review);
    }

    private void updateBookAvgRating(int bookId) {
        List<Review> reviews = reviewRepository.findByBookId(bookId);
        if (reviews.isEmpty()) return;
        double avg = reviews.stream()
                .mapToDouble(r -> r.getRatingPoint())
                .average()
                .orElse(0.0);
        bookRepository.findById(bookId).ifPresent(book -> {
            book.setAvgRating(Math.round(avg * 10.0) / 10.0);
            bookRepository.save(book);
        });
    }
}
