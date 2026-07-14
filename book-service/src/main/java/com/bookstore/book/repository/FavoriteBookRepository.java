package com.bookstore.book.repository;

import com.bookstore.book.entity.FavoriteBook;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FavoriteBookRepository extends JpaRepository<FavoriteBook, Long> {
    List<FavoriteBook> findByUserId(int userId);
    Optional<FavoriteBook> findByUserIdAndBookId(int userId, int bookId);
    boolean existsByUserIdAndBookId(int userId, int bookId);
}
