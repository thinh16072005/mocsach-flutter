package com.bookstore.order.dto.request;

import lombok.Data;

import java.util.List;

@Data
public class CreateOrderRequest {
    private String deliveryAddress;
    private String phoneNumber;
    private String fullName;
    private String note;
    private double totalPriceProduct;
    private double totalPrice;
    private int paymentId;
    private String paymentStatus;
    /** Phương thức giao hàng (bảng delivery). Mặc định 1 nếu không gửi. */
    private int deliveryId;
    private List<OrderItemRequest> orderItems;

    @Data
    public static class OrderItemRequest {
        private int bookId;
        private int quantity;
    }
}
