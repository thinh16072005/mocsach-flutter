package com.bookstore.book.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "favorite_book",
        uniqueConstraints = @UniqueConstraint(columnNames = {"id_user", "id_book"}))
public class FavoriteBook {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_favorite")
    private long idFavorite;

    @Column(name = "id_user", nullable = false)
    private int userId;

    @Column(name = "id_book", nullable = false)
    private int bookId;
}
