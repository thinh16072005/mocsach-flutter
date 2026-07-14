package com.mocsach.user.dto.request;

import lombok.Data;

@Data
public class ChangeAvatarRequest {
    private String avatar; // Base64 encoded image
}
