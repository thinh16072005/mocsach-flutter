package com.bookstore.payment.dto.request;

import lombok.Data;

@Data
public class PayOSRequest {
    private long orderCode;
    private int amount;
    private String description;
    private String returnUrl;
    private String cancelUrl;
    private String buyerName;
    private String buyerEmail;
    private String buyerPhone;
}
