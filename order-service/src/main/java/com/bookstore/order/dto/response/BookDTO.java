package com.bookstore.order.dto.response;

import lombok.Data;

@Data
public class BookDTO {
    private int idBook;
    private String nameBook;
    private String author;
    private double sellPrice;
    private int quantity;
    private double avgRating;
    private int soldQuantity;
}
