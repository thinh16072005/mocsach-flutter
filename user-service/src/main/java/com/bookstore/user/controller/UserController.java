package com.bookstore.user.controller;

import com.bookstore.user.dto.request.ChangeAvatarRequest;
import com.bookstore.user.dto.request.UpdateProfileRequest;
import com.bookstore.user.dto.response.ApiResponse;
import com.bookstore.user.dto.response.UserResponse;
import com.bookstore.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/init")
    public ResponseEntity<ApiResponse<Void>> initProfile(@RequestBody Map<String, Object> payload) {
        return ResponseEntity.ok(userService.initUserProfile(payload));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable int id) {
        ApiResponse<UserResponse> response = userService.getUserById(id);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<ApiResponse<Void>> updateProfile(
            @PathVariable int id,
            @RequestBody UpdateProfileRequest request) {
        ApiResponse<Void> response = userService.updateProfile(id, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/{id}/avatar")
    public ResponseEntity<ApiResponse<Void>> changeAvatar(
            @PathVariable int id,
            @RequestBody ChangeAvatarRequest request) {
        ApiResponse<Void> response = userService.changeAvatar(id, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> updateByAdmin(
            @PathVariable int id,
            @RequestBody Map<String, Object> payload) {
        ApiResponse<Void> response = userService.updateByAdmin(id, payload);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
