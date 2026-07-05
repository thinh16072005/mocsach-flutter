package com.bookstore.couponfeedback.controller;

import com.bookstore.couponfeedback.dto.request.CreateCouponRequest;
import com.bookstore.couponfeedback.dto.response.ApiResponse;
import com.bookstore.couponfeedback.entity.Coupon;
import com.bookstore.couponfeedback.service.CouponService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/coupons")
@RequiredArgsConstructor
public class CouponController {

    private final CouponService couponService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<Coupon>>> getAllCoupons(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(couponService.getAllCoupons(page, size));
    }

    @PostMapping("/batch")
    public ResponseEntity<ApiResponse<List<Coupon>>> createBatch(
            @RequestParam int quantity,
            @RequestBody CreateCouponRequest request) {
        return ResponseEntity.ok(couponService.createBatch(quantity, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCoupon(@PathVariable int id) {
        ApiResponse<Void> response = couponService.deleteCoupon(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<Coupon>> toggleActive(@PathVariable int id) {
        ApiResponse<Coupon> response = couponService.toggleActive(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/use")
    public ResponseEntity<ApiResponse<Coupon>> markAsUsed(@RequestParam String code) {
        ApiResponse<Coupon> response = couponService.markAsUsed(code);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/validate")
    public ResponseEntity<ApiResponse<Coupon>> validateCoupon(@RequestParam String code) {
        ApiResponse<Coupon> response = couponService.validateCoupon(code);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
