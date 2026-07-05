package com.bookstore.payment.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderClient {

    private final RestTemplate restTemplate;

    @Value("${services.order-url}")
    private String orderServiceUrl;

    public void markOrderPaid(int orderId) {
        String url = orderServiceUrl + "/orders/" + orderId + "/status";
        var body = Map.of("paymentStatus", "PAID");
        try {
            restTemplate.exchange(url, HttpMethod.PUT, new HttpEntity<>(body), Void.class);
            log.info("Order {} marked as PAID", orderId);
        } catch (Exception e) {
            log.error("Failed to mark order {} as PAID: {}", orderId, e.getMessage());
            throw e;
        }
    }
}
