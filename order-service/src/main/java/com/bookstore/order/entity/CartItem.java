package com.bookstore.order.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "cart_item")
public class CartItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cart_item")
    private long idCartItem;

    @Column(name = "id_user", nullable = false)
    private int userId;

    @Column(name = "id_book", nullable = false)
    private int bookId;

    @Column(name = "quantity")
    private int quantity;
}
