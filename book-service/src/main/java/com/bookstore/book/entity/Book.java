package com.bookstore.book.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "book")
public class Book {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_book")
    private int idBook;

    @Column(name = "name_book", columnDefinition = "NVARCHAR(255)")
    private String nameBook;

    @Column(name = "author", columnDefinition = "NVARCHAR(255)")
    private String author;

    @Column(name = "description", columnDefinition = "NVARCHAR(MAX)")
    private String description;

    @Column(name = "list_price")
    private double listPrice;

    @Column(name = "sell_price")
    private double sellPrice;

    @Column(name = "quantity")
    private int quantity;

    @Column(name = "avg_rating")
    private double avgRating;

    @Column(name = "sold_quantity")
    private int soldQuantity;

    @Column(name = "discount_percent")
    private int discountPercent;

    // Chỉ 1 field genres — đã fix bug duplicate @ManyToMany
    @ManyToMany(fetch = FetchType.LAZY,
            cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(name = "book_genre",
            joinColumns = @JoinColumn(name = "id_book"),
            inverseJoinColumns = @JoinColumn(name = "id_genre"))
    private List<Genre> genres;

    // R1: exposed in JSON (Image.book keeps @JsonIgnore so no serialization cycle).
    // OSIV (default) lets the LAZY collection serialize, consistent with genres above.
    @OneToMany(mappedBy = "book", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<Image> images;
}
