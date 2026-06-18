package com.bookstore.book.repository;

import com.bookstore.book.entity.Image;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ImageRepository extends JpaRepository<Image, Integer> {
    List<Image> findByBook_IdBook(int bookId);
    void deleteByBook_IdBook(int bookId);
}
