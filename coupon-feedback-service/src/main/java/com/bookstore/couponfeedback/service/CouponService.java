package com.bookstore.couponfeedback.service;

import com.bookstore.couponfeedback.dto.request.CreateCouponRequest;
import com.bookstore.couponfeedback.dto.response.ApiResponse;
import com.bookstore.couponfeedback.entity.Coupon;
import com.bookstore.couponfeedback.repository.CouponRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.RandomStringUtils;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CouponService {

    private final CouponRepository couponRepository;

    public ApiResponse<Page<Coupon>> getAllCoupons(int page, int size) {
        return ApiResponse.success("OK", couponRepository.findAll(PageRequest.of(page, size)));
    }

    public ApiResponse<List<Coupon>> createBatch(int quantity, CreateCouponRequest request) {
        List<Coupon> created = new ArrayList<>();
        for (int i = 0; i < quantity; i++) {
            String code = "BOOK-" + RandomStringUtils.randomAlphanumeric(8).toUpperCase();
            Coupon coupon = Coupon.builder()
                    .code(code)
                    .discountPercent(request.getDiscountPercent())
                    .expiryDate(request.getExpiryDate())
                    .active(true)
                    .used(false)
                    .build();
            created.add(couponRepository.save(coupon));
        }
        log.info("Created {} coupons", quantity);
        return ApiResponse.success("Tạo " + quantity + " mã giảm giá thành công!", created);
    }

    public ApiResponse<Void> deleteCoupon(int id) {
        if (!couponRepository.existsById(id)) return ApiResponse.error("Mã giảm giá không tồn tại!");
        couponRepository.deleteById(id);
        return ApiResponse.success("Xóa mã giảm giá thành công!");
    }

    public ApiResponse<Coupon> toggleActive(int id) {
        Coupon coupon = couponRepository.findById(id).orElse(null);
        if (coupon == null) return ApiResponse.error("Mã giảm giá không tồn tại!");
        coupon.setActive(!coupon.isActive());
        return ApiResponse.success("Cập nhật trạng thái thành công!", couponRepository.save(coupon));
    }

    public ApiResponse<Coupon> markAsUsed(String code) {
        Coupon coupon = couponRepository.findByCode(code).orElse(null);
        if (coupon == null) return ApiResponse.error("Mã giảm giá không tồn tại!");
        if (coupon.isUsed()) return ApiResponse.error("Mã giảm giá đã được sử dụng!");
        coupon.setUsed(true);
        coupon.setActive(false);
        return ApiResponse.success("Đánh dấu đã sử dụng thành công!", couponRepository.save(coupon));
    }

    public ApiResponse<Coupon> validateCoupon(String code) {
        Coupon coupon = couponRepository.findByCode(code).orElse(null);
        if (coupon == null) return ApiResponse.error("Mã giảm giá không tồn tại!");
        if (!coupon.isActive()) return ApiResponse.error("Mã giảm giá đã vô hiệu hóa!");
        if (coupon.isUsed()) return ApiResponse.error("Mã giảm giá đã được sử dụng!");

        java.sql.Date today = java.sql.Date.valueOf(java.time.LocalDate.now());
        if (coupon.getExpiryDate().before(today)) return ApiResponse.error("Mã giảm giá đã hết hạn!");

        return ApiResponse.success("Mã giảm giá hợp lệ!", coupon);
    }
}
