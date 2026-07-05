package com.bookstore.order.client;

import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.dto.response.BookDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;

@FeignClient(name = "book-service", url = "${services.book-url}")
public interface BookClient {

    // R4: book-service wraps the body in ApiResponse; unwrap .getData() at the call site.
    @GetMapping("/books/{id}")
    ApiResponse<BookDTO> getBookById(@PathVariable int id);

    @PutMapping("/books/{id}/stock")
    void updateStock(@PathVariable int id, @RequestBody Map<String, Integer> request);
}
