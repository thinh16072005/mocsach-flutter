package com.bookstore.order.repository;

import com.bookstore.order.entity.Order;
import com.bookstore.order.entity.OrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OrderDetailRepository extends JpaRepository<OrderDetail, Long> {
    List<OrderDetail> findByOrder(Order order);
}
