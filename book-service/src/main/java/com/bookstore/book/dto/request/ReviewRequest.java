package com.bookstore.book.dto.request;

import lombok.Data;

@Data
public class ReviewRequest {
    private int bookId;
    private float ratingPoint;
    private String content;
    private Long orderDetailId;
}
