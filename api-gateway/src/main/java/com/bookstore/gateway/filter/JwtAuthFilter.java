package com.bookstore.gateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.Key;
import java.util.List;

@Slf4j
@Component
public class JwtAuthFilter implements GlobalFilter, Ordered {

    @Value("${jwt.secret}")
    private String jwtSecret;

    // Paths that don't require JWT (matching after /api/v1/)
    private static final List<String> PUBLIC_PATHS = List.of(
            "/auth/register",
            "/auth/login",
            "/auth/activate",
            "/auth/forgot-password",
            "/payments"
    );

    // Path prefixes accessible without token (GET only)
    private static final List<String> PUBLIC_GET_PREFIXES = List.of(
            "/books",
            "/genres",
            "/reviews/book/",
            "/coupons/validate",
            "/deliveries"
    );

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getURI().getPath();
        String method = request.getMethod().name();

        // Strip /api/v1 prefix to get the service path
        String servicePath = path.replaceFirst("^/api/v1", "");

        // Allow public paths
        if (isPublicPath(servicePath, method)) {
            return chain.filter(exchange);
        }

        // Extract token from Authorization header
        String authHeader = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return unauthorizedResponse(exchange, "Missing or invalid Authorization header");
        }

        String token = authHeader.substring(7);
        try {
            Claims claims = extractClaims(token);
            String userId = String.valueOf(claims.get("id"));
            String role = String.valueOf(claims.get("role"));

            // Forward user info as headers to downstream services
            ServerHttpRequest mutatedRequest = request.mutate()
                    .header("X-User-Id", userId)
                    .header("X-User-Role", role)
                    .build();

            return chain.filter(exchange.mutate().request(mutatedRequest).build());

        } catch (Exception e) {
            log.warn("JWT validation failed: {}", e.getMessage());
            return unauthorizedResponse(exchange, "Invalid or expired token");
        }
    }

    private boolean isPublicPath(String servicePath, String method) {
        for (String pub : PUBLIC_PATHS) {
            if (servicePath.startsWith(pub)) return true;
        }
        if ("GET".equals(method)) {
            for (String prefix : PUBLIC_GET_PREFIXES) {
                if (servicePath.startsWith(prefix)) return true;
            }
        }
        return false;
    }

    private Claims extractClaims(String token) {
        Key key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret));
        return Jwts.parserBuilder().setSigningKey(key).build()
                .parseClaimsJws(token).getBody();
    }

    private Mono<Void> unauthorizedResponse(ServerWebExchange exchange, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().add("Content-Type", "application/json");
        var body = response.bufferFactory()
                .wrap(("{\"success\":false,\"message\":\"" + message + "\"}").getBytes());
        return response.writeWith(Mono.just(body));
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
