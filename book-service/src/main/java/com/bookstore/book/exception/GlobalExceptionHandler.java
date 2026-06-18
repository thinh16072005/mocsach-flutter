package com.bookstore.book.exception;

import com.bookstore.book.dto.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.catalina.connector.ClientAbortException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.async.AsyncRequestNotUsableException;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** Client (app/gateway) đóng kết nối trước khi gửi xong JSON — thường do payload lớn hoặc timeout, không phải lỗi nghiệp vụ. */
    @ExceptionHandler({ClientAbortException.class, AsyncRequestNotUsableException.class})
    public void handleClientAbort(Exception e) {
        log.debug("Client disconnected before response completed: {}", e.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception e) {
        if (isClientAbort(e)) {
            log.debug("Client disconnected: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
        }
        log.error("Unhandled exception: {}", e.getMessage(), e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Lỗi hệ thống: " + e.getMessage()));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Void>> handleRuntimeException(RuntimeException e) {
        log.warn("Runtime exception: {}", e.getMessage());
        return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
    }

    private static boolean isClientAbort(Throwable e) {
        while (e != null) {
            if (e instanceof ClientAbortException || e instanceof AsyncRequestNotUsableException) {
                return true;
            }
            e = e.getCause();
        }
        return false;
    }
}
