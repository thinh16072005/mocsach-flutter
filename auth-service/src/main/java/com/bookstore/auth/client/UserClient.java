package com.bookstore.auth.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;

@FeignClient(name = "user-service", url = "${services.user-url}")
public interface UserClient {

    @PostMapping("/users/init")
    void initUserProfile(@RequestBody Map<String, Object> payload);
}
