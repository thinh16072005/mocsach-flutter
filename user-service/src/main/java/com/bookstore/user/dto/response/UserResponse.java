package com.bookstore.user.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Date;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private int idUser;
    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private Character gender;
    private Date dateOfBirth;
    private String deliveryAddress;
    private String avatar;
}
