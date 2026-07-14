package com.bookstore.payment.controller;

import com.bookstore.payment.dto.request.PayOSRequest;
import com.bookstore.payment.dto.response.ApiResponse;
import com.bookstore.payment.dto.response.PayOSLinkResponse;
import com.bookstore.payment.entity.Payment;
import com.bookstore.payment.service.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.payos.model.webhooks.Webhook;

import java.util.List;

@Slf4j

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Payment>>> getAllPaymentMethods() {
        return ResponseEntity.ok(paymentService.getAllPaymentMethods());
    }

    @PostMapping("/payos/create")
    public ResponseEntity<ApiResponse<PayOSLinkResponse>> createPayOSLink(@RequestBody PayOSRequest request) {
        ApiResponse<PayOSLinkResponse> response = paymentService.createPayOSLink(request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/payos/verify/{orderCode}")
    public ResponseEntity<ApiResponse<String>> verifyPayOS(@PathVariable long orderCode) {
        ApiResponse<String> response = paymentService.verifyPayOSPayment(orderCode);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/payos/webhook")
    public ResponseEntity<String> handleWebhook(@RequestBody Webhook webhook) {
        try {
            paymentService.handlePayOSWebhook(webhook);
            return ResponseEntity.ok("OK");
        } catch (Exception e) {
            log.warn("PayOS webhook rejected: {}", e.getMessage());
            return ResponseEntity.badRequest().body("Invalid webhook");
        }
    }
}
