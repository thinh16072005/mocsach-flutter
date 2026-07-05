package com.bookstore.payment.service;

import com.bookstore.payment.client.OrderClient;
import com.bookstore.payment.dto.request.PayOSRequest;
import com.bookstore.payment.dto.response.ApiResponse;
import com.bookstore.payment.dto.response.PayOSLinkResponse;
import com.bookstore.payment.entity.Payment;
import com.bookstore.payment.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import vn.payos.PayOS;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;
import vn.payos.model.v2.paymentRequests.PaymentLink;
import vn.payos.model.v2.paymentRequests.PaymentLinkItem;
import vn.payos.model.v2.paymentRequests.PaymentLinkStatus;
import vn.payos.model.webhooks.Webhook;
import vn.payos.model.webhooks.WebhookData;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final PayOS payOS;
    private final OrderClient orderClient;

    @Value("${payos.return-url}")
    private String defaultReturnUrl;

    @Value("${payos.cancel-url}")
    private String defaultCancelUrl;

    public ApiResponse<List<Payment>> getAllPaymentMethods() {
        return ApiResponse.success("OK", paymentRepository.findAll());
    }

    /** Tạo link + QR — SDK 2.x giống BookStoreSBA (hỗ trợ expiredAt). */
    public ApiResponse<PayOSLinkResponse> createPayOSLink(PayOSRequest request) {
        if (request.getOrderCode() <= 0) {
            return ApiResponse.error("Mã đơn hàng không hợp lệ!");
        }
        if (request.getAmount() <= 0) {
            return ApiResponse.error("Số tiền thanh toán phải lớn hơn 0!");
        }
        try {
            String returnUrl = request.getReturnUrl() != null && !request.getReturnUrl().isBlank()
                    ? request.getReturnUrl() : defaultReturnUrl;
            String cancelUrl = request.getCancelUrl() != null && !request.getCancelUrl().isBlank()
                    ? request.getCancelUrl() : defaultCancelUrl;
            String description = request.getDescription() != null && !request.getDescription().isBlank()
                    ? request.getDescription() : "Don hang " + request.getOrderCode();

            long amount = request.getAmount();
            PaymentLinkItem item = PaymentLinkItem.builder()
                    .name(description)
                    .quantity(1)
                    .price(amount)
                    .build();

            CreatePaymentLinkRequest paymentData = CreatePaymentLinkRequest.builder()
                    .orderCode((long) request.getOrderCode())
                    .amount(amount)
                    .description(description)
                    .returnUrl(returnUrl)
                    .cancelUrl(cancelUrl)
                    .buyerName(request.getBuyerName())
                    .buyerEmail(request.getBuyerEmail())
                    .buyerPhone(request.getBuyerPhone())
                    .item(item)
                    .build();

            CreatePaymentLinkResponse responseData = payOS.paymentRequests().create(paymentData);
            log.info("PayOS link created for orderCode={}", request.getOrderCode());

            PayOSLinkResponse link = PayOSLinkResponse.builder()
                    .checkoutUrl(responseData.getCheckoutUrl())
                    .qrCode(responseData.getQrCode())
                    .orderCode(responseData.getOrderCode())
                    .amount(responseData.getAmount() != null ? responseData.getAmount().intValue() : request.getAmount())
                    .accountNumber(responseData.getAccountNumber())
                    .accountName(responseData.getAccountName())
                    .description(responseData.getDescription())
                    .build();
            return ApiResponse.success("Tạo link thanh toán thành công!", link);
        } catch (Exception e) {
            log.error("PayOS error: {}", e.getMessage());
            return ApiResponse.error("Tạo link thanh toán thất bại: " + e.getMessage());
        }
    }

    public void handlePayOSWebhook(Webhook webhook) throws Exception {
        WebhookData data = payOS.webhooks().verify(webhook);
        if (data.getOrderCode() == null) {
            throw new IllegalArgumentException("Webhook thiếu orderCode");
        }
        markOrderPaidFromPayOS(data.getOrderCode().intValue());
    }

    public ApiResponse<String> verifyPayOSPayment(long orderCode) {
        try {
            PaymentLink info = payOS.paymentRequests().get(orderCode);
            if (info == null) {
                return ApiResponse.error("Không tìm thấy giao dịch PayOS!");
            }
            if (isPayOSPaid(info)) {
                markOrderPaidFromPayOS((int) orderCode);
                return ApiResponse.success("Thanh toán đã được xác nhận!", "PAID");
            }
            String status = info.getStatus() != null ? info.getStatus().name() : "PENDING";
            if ("CANCELLED".equalsIgnoreCase(status)) {
                return ApiResponse.success("Đã hủy thanh toán", "CANCELLED");
            }
            return ApiResponse.success("Chưa thanh toán", status);
        } catch (Exception e) {
            log.error("Verify PayOS failed for orderCode={}: {}", orderCode, e.getMessage());
            return ApiResponse.error("Không thể kiểm tra thanh toán: " + e.getMessage());
        }
    }

    private boolean isPayOSPaid(PaymentLink info) {
        if (info.getStatus() == PaymentLinkStatus.PAID) {
            return true;
        }
        Long remaining = info.getAmountRemaining();
        return remaining != null && remaining == 0
                && info.getAmountPaid() != null && info.getAmountPaid() > 0;
    }

    private void markOrderPaidFromPayOS(int orderId) {
        log.info("PayOS payment confirmed for orderId={}", orderId);
        orderClient.markOrderPaid(orderId);
    }
}
