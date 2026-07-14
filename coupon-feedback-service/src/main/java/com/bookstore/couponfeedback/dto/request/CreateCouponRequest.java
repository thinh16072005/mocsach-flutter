package com.bookstore.couponfeedback.dto.request;

import lombok.Data;

import java.sql.Date;

@Data
public class CreateCouponRequest {
    private int discountPercent;
    private Date expiryDate;
}
