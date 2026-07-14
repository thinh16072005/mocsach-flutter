package com.bookstore.order.dto.request;

import lombok.Data;

@Data
public class UpdateOrderRequest {
    private String status;
    private String paymentStatus;
}
