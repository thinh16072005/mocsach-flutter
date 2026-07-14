package com.bookstore.couponfeedback.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Date;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "coupon")
public class Coupon {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_coupon")
    private int idCoupon;

    @Column(name = "code", unique = true, nullable = false)
    private String code;

    @Column(name = "discount_percent", nullable = false)
    private int discountPercent;

    @Column(name = "expiry_date", nullable = false)
    private Date expiryDate;

    @Column(name = "is_active", nullable = false)
    @JsonProperty("isActive")
    private boolean active;

    @Column(name = "is_used", nullable = false)
    @JsonProperty("isUsed")
    private boolean used;
}
