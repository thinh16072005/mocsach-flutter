package com.mocsach.auth.controller;

import com.mocsach.auth.dto.request.ChangePasswordRequest;
import com.mocsach.auth.dto.request.ForgotPasswordRequest;
import com.mocsach.auth.dto.request.LoginRequest;
import com.mocsach.auth.dto.request.RegisterRequest;
import com.mocsach.auth.dto.response.ApiResponse;
import com.mocsach.auth.dto.response.JwtResponse;
import com.mocsach.auth.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Void>> register(@RequestBody RegisterRequest request) {
        ApiResponse<Void> response = authService.register(request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/register-by-admin")
    public ResponseEntity<ApiResponse<Void>> registerByAdmin(@RequestBody RegisterRequest request) {
        ApiResponse<Void> response = authService.registerByAdmin(request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @GetMapping("/activate")
    public ResponseEntity<ApiResponse<Void>> activate(@RequestParam String email,
                                                       @RequestParam String code) {
        ApiResponse<Void> response = authService.activateAccount(email, code);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<JwtResponse>> login(@RequestBody LoginRequest request) {
        ApiResponse<JwtResponse> response = authService.login(request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        ApiResponse<Void> response = authService.forgotPassword(request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }

    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @RequestHeader("X-User-Id") int userId,
            @RequestBody ChangePasswordRequest request) {
        ApiResponse<Void> response = authService.changePassword(userId, request);
        return response.isSuccess() ? ResponseEntity.ok(response) : ResponseEntity.badRequest().body(response);
    }
}
