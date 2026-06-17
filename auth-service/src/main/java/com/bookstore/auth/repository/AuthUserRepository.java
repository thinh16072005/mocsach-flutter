package com.bookstore.auth.repository;

import com.bookstore.auth.entity.AuthUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AuthUserRepository extends JpaRepository<AuthUser, Integer> {
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    Optional<AuthUser> findByUsername(String username);
    Optional<AuthUser> findByEmail(String email);
}
