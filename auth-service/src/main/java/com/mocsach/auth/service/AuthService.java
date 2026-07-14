package com.mocsach.auth.service;

import com.mocsach.auth.client.UserClient;
import com.mocsach.auth.dto.request.ChangePasswordRequest;
import com.mocsach.auth.dto.request.ForgotPasswordRequest;
import com.mocsach.auth.dto.request.LoginRequest;
import com.mocsach.auth.dto.request.RegisterRequest;
import com.mocsach.auth.dto.response.ApiResponse;
import com.mocsach.auth.dto.response.JwtResponse;
import com.mocsach.auth.entity.AuthUser;
import com.mocsach.auth.repository.AuthUserRepository;
import com.mocsach.auth.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.RandomStringUtils;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthUserRepository authUserRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final EmailService emailService;
    private final UserClient userClient;

    public ApiResponse<Void> register(RegisterRequest request) {
        if (authUserRepository.existsByUsername(request.getUsername())) {
            return ApiResponse.error("Username đã tồn tại.");
        }
        if (authUserRepository.existsByEmail(request.getEmail())) {
            return ApiResponse.error("Email đã tồn tại.");
        }

        AuthUser authUser = createAndSaveAuthUser(request.getUsername(), request.getPassword(),
                request.getEmail(), "CUSTOMER");

        // Tạo profile user trong user-service qua Feign
        try {
            userClient.initUserProfile(Map.of(
                    "userId", authUser.getId(),
                    "email", authUser.getEmail(),
                    "firstName", request.getFirstName() != null ? request.getFirstName() : "",
                    "lastName", request.getLastName() != null ? request.getLastName() : ""
            ));
        } catch (Exception e) {
            log.warn("Could not init user profile for userId={}: {}", authUser.getId(), e.getMessage());
        }

        emailService.sendActivationEmail(authUser.getEmail(), authUser.getActivationCode());
        return ApiResponse.success("Đăng ký thành công! Vui lòng kiểm tra email để kích hoạt tài khoản.");
    }

    public ApiResponse<Void> registerByAdmin(RegisterRequest request) {
        if (authUserRepository.existsByUsername(request.getUsername())) {
            return ApiResponse.error("Username đã tồn tại.");
        }
        if (authUserRepository.existsByEmail(request.getEmail())) {
            return ApiResponse.error("Email đã tồn tại.");
        }

        AuthUser authUser = createAndSaveAuthUser(request.getUsername(), request.getPassword(),
                request.getEmail(), "CUSTOMER");

        try {
            userClient.initUserProfile(Map.of(
                    "userId", authUser.getId(),
                    "email", authUser.getEmail(),
                    "firstName", request.getFirstName() != null ? request.getFirstName() : "",
                    "lastName", request.getLastName() != null ? request.getLastName() : ""
            ));
        } catch (Exception e) {
            log.warn("Could not init user profile: {}", e.getMessage());
        }

        emailService.sendActivationEmail(authUser.getEmail(), authUser.getActivationCode());
        return ApiResponse.success("Người dùng được tạo thành công! Email xác nhận đã được gửi.");
    }

    private AuthUser createAndSaveAuthUser(String username, String rawPassword, String email, String role) {
        AuthUser authUser = AuthUser.builder()
                .username(username)
                .password(passwordEncoder.encode(rawPassword))
                .email(email)
                .enabled(false)
                .activationCode(RandomStringUtils.randomNumeric(6))
                .role(role)
                .build();
        return authUserRepository.save(authUser);
    }

    public ApiResponse<Void> activateAccount(String email, String code) {
        AuthUser user = authUserRepository.findByEmail(email)
                .orElse(null);
        if (user == null) {
            return ApiResponse.error("Người dùng không tồn tại!");
        }
        if (user.isEnabled()) {
            return ApiResponse.error("Tài khoản đã được kích hoạt.");
        }
        if (!user.getActivationCode().equals(code)) {
            return ApiResponse.error("Mã kích hoạt không chính xác!");
        }
        user.setEnabled(true);
        authUserRepository.save(user);
        return ApiResponse.success("Kích hoạt tài khoản thành công!");
    }

    public ApiResponse<JwtResponse> login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
            );
            if (!authentication.isAuthenticated()) {
                return ApiResponse.error("Xác thực không thành công.");
            }

            AuthUser user = authUserRepository.findByUsername(request.getUsername())
                    .orElseThrow();
            if (!user.isEnabled()) {
                return ApiResponse.error("Tài khoản chưa được kích hoạt hoặc đã bị khóa!");
            }

            String token = jwtService.generateToken(user);
            return ApiResponse.success("Đăng nhập thành công!", new JwtResponse(token));

        } catch (AuthenticationException e) {
            return ApiResponse.error("Tên đăng nhập hoặc mật khẩu không đúng!");
        }
    }

    public ApiResponse<Void> forgotPassword(ForgotPasswordRequest request) {
        AuthUser user = authUserRepository.findByEmail(request.getEmail())
                .orElse(null);
        if (user == null) {
            return ApiResponse.error("Email không tồn tại trong hệ thống.");
        }

        String tempPassword = RandomStringUtils.random(10, true, true);
        user.setPassword(passwordEncoder.encode(tempPassword));
        authUserRepository.save(user);

        emailService.sendForgotPasswordEmail(user.getEmail(), tempPassword);
        return ApiResponse.success("Mật khẩu tạm thời đã được gửi đến email của bạn.");
    }

    public ApiResponse<Void> changePassword(int userId, ChangePasswordRequest request) {
        AuthUser user = authUserRepository.findById(userId).orElse(null);
        if (user == null) {
            return ApiResponse.error("Người dùng không tồn tại!");
        }

        if (request.getCurrentPassword() == null || request.getCurrentPassword().isBlank()) {
            return ApiResponse.error("Mật khẩu hiện tại không được để trống!");
        }
        if (request.getNewPassword() == null || request.getNewPassword().isBlank()) {
            return ApiResponse.error("Mật khẩu mới không được để trống!");
        }
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            return ApiResponse.error("Mật khẩu hiện tại không đúng!");
        }
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            return ApiResponse.error("Mật khẩu mới và xác nhận mật khẩu không khớp!");
        }
        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            return ApiResponse.error("Mật khẩu mới phải khác mật khẩu hiện tại!");
        }
        if (request.getNewPassword().length() < 8) {
            return ApiResponse.error("Mật khẩu mới phải có ít nhất 8 ký tự!");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        authUserRepository.save(user);
        return ApiResponse.success("Đổi mật khẩu thành công!");
    }
}
