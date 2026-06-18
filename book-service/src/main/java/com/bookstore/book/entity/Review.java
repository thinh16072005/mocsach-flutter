package com.bookstore.book.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Timestamp;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "review")
public class Review {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_review")
    private long idReview;

    @Column(name = "content", columnDefinition = "NVARCHAR(MAX)")
    private String content;

    @Column(name = "rating_point")
    private float ratingPoint;

    @Column(name = "timestamp")
    private Timestamp timestamp;

    @Column(name = "id_book", nullable = false)
    private int bookId;

    @Column(name = "id_user", nullable = false)
    private int userId;

    @Column(name = "id_order_detail")
    private Long orderDetailId;
}
