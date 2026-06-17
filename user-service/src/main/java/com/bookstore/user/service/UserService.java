package com.bookstore.user.service;

import com.bookstore.user.dto.request.ChangeAvatarRequest;
import com.bookstore.user.dto.request.UpdateProfileRequest;
import com.bookstore.user.dto.response.ApiResponse;
import com.bookstore.user.dto.response.UserResponse;
import com.bookstore.user.entity.User;
import com.bookstore.user.repository.UserRepository;
import com.bookstore.user.util.Base64ToMultipartFile;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final CloudinaryService cloudinaryService;

    // Gọi từ auth-service khi đăng ký
    public ApiResponse<Void> initUserProfile(Map<String, Object> payload) {
        int userId = (Integer) payload.get("userId");
        String email = (String) payload.get("email");
        String firstName = payload.getOrDefault("firstName", "").toString();
        String lastName = payload.getOrDefault("lastName", "").toString();

        if (userRepository.existsById(userId)) {
            return ApiResponse.error("User profile đã tồn tại.");
        }

        User user = User.builder()
                .idUser(userId)
                .email(email)
                .firstName(firstName)
                .lastName(lastName)
                .avatar("")
                .build();
        userRepository.save(user);
        return ApiResponse.success("Profile đã được tạo.");
    }

    public ApiResponse<List<UserResponse>> getAllUsers() {
        List<UserResponse> users = userRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
        return ApiResponse.success("Danh sách người dùng", users);
    }

    public ApiResponse<UserResponse> getUserById(int id) {
        User user = userRepository.findById(id)
                .orElse(null);
        if (user == null) return ApiResponse.error("Người dùng không tồn tại!");
        return ApiResponse.success("OK", toResponse(user));
    }

    public ApiResponse<Void> updateProfile(int userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElse(null);
        if (user == null) return ApiResponse.error("Người dùng không tồn tại!");

        if (isNotBlank(request.getFirstName())) user.setFirstName(request.getFirstName());
        if (isNotBlank(request.getLastName())) user.setLastName(request.getLastName());
        if (isNotBlank(request.getPhoneNumber())) user.setPhoneNumber(request.getPhoneNumber());
        if (request.getDeliveryAddress() != null) user.setDeliveryAddress(request.getDeliveryAddress());
        if (request.getDateOfBirth() != null)
            user.setDateOfBirth(new java.sql.Date(request.getDateOfBirth().getTime()));
        if (isNotBlank(request.getGender()))
            user.setGender(request.getGender().charAt(0));

        userRepository.save(user);
        return ApiResponse.success("Cập nhật thông tin thành công!");
    }

    public ApiResponse<Void> changeAvatar(int userId, ChangeAvatarRequest request) {
        User user = userRepository.findById(userId)
                .orElse(null);
        if (user == null) return ApiResponse.error("Người dùng không tồn tại!");

        String base64 = request.getAvatar();
        if (!Base64ToMultipartFile.isBase64(base64)) {
            return ApiResponse.error("Dữ liệu ảnh không hợp lệ!");
        }

        // Xóa ảnh cũ
        if (user.getAvatar() != null && !user.getAvatar().isEmpty()) {
            cloudinaryService.deleteImage(user.getAvatar());
        }

        MultipartFile file = Base64ToMultipartFile.convert(base64);
        String avatarUrl = cloudinaryService.uploadImage(file, "User_" + userId);
        user.setAvatar(avatarUrl);
        userRepository.save(user);
        return ApiResponse.success("Đổi avatar thành công!");
    }

    public ApiResponse<Void> updateByAdmin(int userId, Map<String, Object> payload) {
        User user = userRepository.findById(userId)
                .orElse(null);
        if (user == null) return ApiResponse.error("Người dùng không tồn tại!");

        if (payload.containsKey("firstName")) user.setFirstName((String) payload.get("firstName"));
        if (payload.containsKey("lastName")) user.setLastName((String) payload.get("lastName"));
        if (payload.containsKey("phoneNumber")) user.setPhoneNumber((String) payload.get("phoneNumber"));
        if (payload.containsKey("deliveryAddress")) user.setDeliveryAddress((String) payload.get("deliveryAddress"));

        userRepository.save(user);
        return ApiResponse.success("Cập nhật thành công.");
    }

    private UserResponse toResponse(User u) {
        return UserResponse.builder()
                .idUser(u.getIdUser())
                .firstName(u.getFirstName())
                .lastName(u.getLastName())
                .email(u.getEmail())
                .phoneNumber(u.getPhoneNumber())
                .gender(u.getGender())
                .dateOfBirth(u.getDateOfBirth())
                .deliveryAddress(u.getDeliveryAddress())
                .avatar(u.getAvatar())
                .build();
    }

    private boolean isNotBlank(String s) {
        return s != null && !s.trim().isEmpty();
    }
}
