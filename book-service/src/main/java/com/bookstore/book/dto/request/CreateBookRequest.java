package com.bookstore.book.dto.request;

import lombok.Data;

import java.util.List;

@Data
public class CreateBookRequest {
    private String nameBook;
    private String author;
    private String description;
    private double listPrice;
    private int quantity;
    private int discountPercent;
    private List<Integer> genreIds;
}
