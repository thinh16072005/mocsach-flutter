package com.bookstore.order.service;

import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.entity.CartItem;
import com.bookstore.order.repository.CartItemRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CartService {

    private final CartItemRepository cartItemRepository;

    public ApiResponse<List<CartItem>> getCart(int userId) {
        return ApiResponse.success("OK", cartItemRepository.findByUserId(userId));
    }

    public ApiResponse<CartItem> addItem(int userId, int bookId, int quantity) {
        CartItem existing = cartItemRepository.findByUserIdAndBookId(userId, bookId).orElse(null);
        if (existing != null) {
            existing.setQuantity(existing.getQuantity() + quantity);
            return ApiResponse.success("Cập nhật giỏ hàng!", cartItemRepository.save(existing));
        }
        CartItem item = CartItem.builder()
                .userId(userId)
                .bookId(bookId)
                .quantity(quantity)
                .build();
        return ApiResponse.success("Đã thêm vào giỏ hàng!", cartItemRepository.save(item));
    }

    public ApiResponse<CartItem> updateQuantity(long cartItemId, int quantity) {
        CartItem item = cartItemRepository.findById(cartItemId).orElse(null);
        if (item == null) return ApiResponse.error("Không tìm thấy item trong giỏ hàng!");
        item.setQuantity(quantity);
        return ApiResponse.success("Cập nhật số lượng thành công!", cartItemRepository.save(item));
    }

    public ApiResponse<Void> removeItem(long cartItemId) {
        if (!cartItemRepository.existsById(cartItemId)) {
            return ApiResponse.error("Không tìm thấy item trong giỏ hàng!");
        }
        cartItemRepository.deleteById(cartItemId);
        return ApiResponse.success("Đã xóa khỏi giỏ hàng!");
    }

    @Transactional
    public void clearCart(int userId) {
        cartItemRepository.deleteByUserId(userId);
        log.info("Cleared cart for userId={}", userId);
    }
}
