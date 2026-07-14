package com.bookstore.order.entity;

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
@Table(name = "delivery")
public class Delivery {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_delivery")
    private int idDelivery;

    @Column(name = "name_delivery", columnDefinition = "NVARCHAR(255)")
    private String nameDelivery;

    @Column(name = "fee_delivery")
    private double feeDelivery;
}
