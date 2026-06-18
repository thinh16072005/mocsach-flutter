package com.bookstore.book.service;

import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.entity.FavoriteBook;
import com.bookstore.book.repository.BookRepository;
import com.bookstore.book.repository.FavoriteBookRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteBookRepository favoriteBookRepository;
    private final BookRepository bookRepository;

    public ApiResponse<List<FavoriteBook>> getFavoritesByUser(int userId) {
        return ApiResponse.success("OK", favoriteBookRepository.findByUserId(userId));
    }

    public ApiResponse<FavoriteBook> addFavorite(int userId, int bookId) {
        if (!bookRepository.existsById(bookId)) return ApiResponse.error("Sách không tồn tại!");
        if (favoriteBookRepository.existsByUserIdAndBookId(userId, bookId)) {
            return ApiResponse.error("Sách đã có trong danh sách yêu thích!");
        }
        FavoriteBook favorite = FavoriteBook.builder()
                .userId(userId)
                .bookId(bookId)
                .build();
        return ApiResponse.success("Đã thêm vào yêu thích!", favoriteBookRepository.save(favorite));
    }

    public ApiResponse<Void> removeFavorite(int userId, int bookId) {
        FavoriteBook favorite = favoriteBookRepository.findByUserIdAndBookId(userId, bookId)
                .orElse(null);
        if (favorite == null) return ApiResponse.error("Không tìm thấy sách yêu thích!");
        favoriteBookRepository.delete(favorite);
        return ApiResponse.success("Đã xóa khỏi danh sách yêu thích!");
    }
}
