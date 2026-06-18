package com.bookstore.book.controller;

import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.entity.FavoriteBook;
import com.bookstore.book.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<FavoriteBook>>> getFavoritesByUser(@PathVariable int userId) {
        return ResponseEntity.ok(favoriteService.getFavoritesByUser(userId));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FavoriteBook>> addFavorite(
            @RequestHeader("X-User-Id") int userId,
            @RequestBody Map<String, Integer> payload) {
        int bookId = payload.get("bookId");
        ApiResponse<FavoriteBook> response = favoriteService.addFavorite(userId, bookId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @DeleteMapping("/{bookId}/user/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeFavorite(
            @PathVariable int bookId,
            @PathVariable int userId) {
        ApiResponse<Void> response = favoriteService.removeFavorite(userId, bookId);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
