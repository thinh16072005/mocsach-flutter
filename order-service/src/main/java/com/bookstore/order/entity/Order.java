package com.bookstore.order.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Date;
import java.util.List;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_order")
    private int idOrder;

    @Column(name = "date_created")
    private Date dateCreated;

    @Column(name = "delivery_address", columnDefinition = "NVARCHAR(255)")
    private String deliveryAddress;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(name = "full_name", columnDefinition = "NVARCHAR(255)")
    private String fullName;

    @Column(name = "total_price_product")
    private double totalPriceProduct;

    @Column(name = "fee_delivery")
    private double feeDelivery;

    @Column(name = "fee_payment")
    private double feePayment;

    @Column(name = "total_price")
    private double totalPrice;

    @Column(name = "status", columnDefinition = "NVARCHAR(50)")
    private String status;

    @Column(name = "note", columnDefinition = "NVARCHAR(255)")
    private String note;

    @Column(name = "payment_status", columnDefinition = "NVARCHAR(20)")
    private String paymentStatus;

    @Column(name = "id_user", nullable = false)
    private int userId;

    @Column(name = "id_payment")
    private int paymentId;

    @Column(name = "id_delivery")
    private int deliveryId;

    // R2: exposed in JSON (OrderDetail.order keeps @JsonIgnore so no serialization cycle).
    // OSIV (default) lets the LAZY collection serialize on getOrder*/getAllOrders.
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    private List<OrderDetail> listOrderDetails;
}
