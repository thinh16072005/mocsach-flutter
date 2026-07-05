package com.bookstore.order.repository;

import com.bookstore.order.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {
    List<CartItem> findByUserId(int userId);
    Optional<CartItem> findByUserIdAndBookId(int userId, int bookId);
    void deleteByUserId(int userId);
}
