package com.bookstore.order.controller;

import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.entity.CartItem;
import com.bookstore.order.service.CartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<List<CartItem>>> getCart(@PathVariable int userId) {
        return ResponseEntity.ok(cartService.getCart(userId));
    }

    @PostMapping("/items")
    public ResponseEntity<ApiResponse<CartItem>> addItem(
            @RequestHeader("X-User-Id") int userId,
            @RequestBody Map<String, Integer> payload) {
        int bookId = payload.get("bookId");
        int quantity = payload.getOrDefault("quantity", 1);
        ApiResponse<CartItem> response = cartService.addItem(userId, bookId, quantity);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/items/{id}")
    public ResponseEntity<ApiResponse<CartItem>> updateQuantity(
            @PathVariable long id,
            @RequestBody Map<String, Integer> payload) {
        int quantity = payload.get("quantity");
        ApiResponse<CartItem> response = cartService.updateQuantity(id, quantity);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @DeleteMapping("/items/{id}")
    public ResponseEntity<ApiResponse<Void>> removeItem(@PathVariable long id) {
        ApiResponse<Void> response = cartService.removeItem(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
