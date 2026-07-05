package com.bookstore.couponfeedback.repository;

import com.bookstore.couponfeedback.entity.Coupon;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CouponRepository extends JpaRepository<Coupon, Integer> {
    Optional<Coupon> findByCode(String code);
    Page<Coupon> findAll(Pageable pageable);
}
