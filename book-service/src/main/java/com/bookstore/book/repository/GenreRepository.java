package com.bookstore.book.repository;

import com.bookstore.book.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GenreRepository extends JpaRepository<Genre, Integer> {
    boolean existsByNameGenre(String nameGenre);
}
