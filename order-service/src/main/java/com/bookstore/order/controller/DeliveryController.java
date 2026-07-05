package com.bookstore.order.controller;

import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.entity.Delivery;
import com.bookstore.order.repository.DeliveryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/deliveries")
@RequiredArgsConstructor
public class DeliveryController {

    private final DeliveryRepository deliveryRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Delivery>>> getAllDeliveries() {
        return ResponseEntity.ok(ApiResponse.success("OK", deliveryRepository.findAll()));
    }
}
