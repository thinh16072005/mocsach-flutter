package com.bookstore.order.controller;

import com.bookstore.order.dto.request.CreateOrderRequest;
import com.bookstore.order.dto.request.UpdateOrderRequest;
import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.entity.Order;
import com.bookstore.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Order>>> getAllOrders() {
        return ResponseEntity.ok(orderService.getAllOrders());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Order>>> getOrdersByUser(@PathVariable int userId) {
        return ResponseEntity.ok(orderService.getOrdersByUser(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Order>> getOrderById(@PathVariable int id) {
        ApiResponse<Order> response = orderService.getOrderById(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Order>> createOrder(
            @RequestHeader("X-User-Id") int userId,
            @RequestBody CreateOrderRequest request) {
        ApiResponse<Order> response = orderService.createOrder(userId, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<Order>> updateOrderStatus(
            @PathVariable int id,
            @RequestBody UpdateOrderRequest request) {
        ApiResponse<Order> response = orderService.updateOrderStatus(id, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Order>> cancelOrder(@PathVariable int id) {
        UpdateOrderRequest req = new UpdateOrderRequest();
        req.setStatus("Bị huỷ");
        req.setPaymentStatus("CANCELLED");
        ApiResponse<Order> response = orderService.updateOrderStatus(id, req);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
