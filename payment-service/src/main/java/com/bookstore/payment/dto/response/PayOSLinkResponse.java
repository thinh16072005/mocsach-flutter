package com.bookstore.payment.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayOSLinkResponse {
    private String checkoutUrl;
    private String qrCode;
    private Long orderCode;
    private Integer amount;
    private String accountNumber;
    private String accountName;
    private String description;
}
