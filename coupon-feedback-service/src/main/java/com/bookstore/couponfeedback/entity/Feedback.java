package com.bookstore.couponfeedback.entity;

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
@Table(name = "feedback")
public class Feedback {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_feedback")
    private long idFeedback;

    @Column(name = "content", columnDefinition = "NVARCHAR(MAX)")
    private String content;

    @Column(name = "id_user")
    private int userId;

    @Column(name = "is_read")
    private boolean read;

    @Column(name = "created_at")
    private Timestamp createdAt;
}
