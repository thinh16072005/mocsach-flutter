package com.bookstore.book.repository;

import com.bookstore.book.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByBookId(int bookId);
    boolean existsByOrderDetailId(Long orderDetailId);
}
