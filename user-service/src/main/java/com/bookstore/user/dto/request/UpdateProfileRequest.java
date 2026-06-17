package com.bookstore.user.dto.request;

import lombok.Data;

import java.util.Date;

@Data
public class UpdateProfileRequest {
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String deliveryAddress;
    private Date dateOfBirth;
    private String gender;
}
