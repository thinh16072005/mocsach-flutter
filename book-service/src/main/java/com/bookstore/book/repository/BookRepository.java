package com.bookstore.book.repository;

import com.bookstore.book.entity.Book;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookRepository extends JpaRepository<Book, Integer> {
    Page<Book> findByNameBookContainingIgnoreCase(String name, Pageable pageable);
    Page<Book> findByGenres_IdGenre(int genreId, Pageable pageable);
    Page<Book> findByNameBookContainingIgnoreCaseAndGenres_IdGenre(String name, int genreId, Pageable pageable);
}
