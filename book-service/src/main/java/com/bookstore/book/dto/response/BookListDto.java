package com.bookstore.book.dto.response;

import com.bookstore.book.entity.Book;
import com.bookstore.book.entity.Genre;
import com.bookstore.book.entity.Image;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Sách cho danh sách / carousel — không gửi {@code description} (NVARCHAR(MAX)) để tránh response quá lớn và Broken pipe.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BookListDto {
    private int idBook;
    private String nameBook;
    private String author;
    private double listPrice;
    private double sellPrice;
    private int quantity;
    private double avgRating;
    private int soldQuantity;
    private int discountPercent;
    private List<Genre> genres;
    private List<Image> images;

    public static BookListDto from(Book book) {
        return BookListDto.builder()
                .idBook(book.getIdBook())
                .nameBook(book.getNameBook())
                .author(book.getAuthor())
                .listPrice(book.getListPrice())
                .sellPrice(book.getSellPrice())
                .quantity(book.getQuantity())
                .avgRating(book.getAvgRating())
                .soldQuantity(book.getSoldQuantity())
                .discountPercent(book.getDiscountPercent())
                .genres(book.getGenres())
                .images(book.getImages())
                .build();
    }
}
