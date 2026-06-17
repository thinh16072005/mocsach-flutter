package com.mocsach.user.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Date;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "[user]")
public class User {
    @Id
    @Column(name = "id_user")
    private int idUser; // Khớp với id trong auth-service

    @Column(name = "first_name", columnDefinition = "NVARCHAR(255)")
    private String firstName;

    @Column(name = "last_name", columnDefinition = "NVARCHAR(255)")
    private String lastName;

    @Column(name = "email")
    private String email;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(name = "gender")
    private Character gender;

    @Column(name = "date_of_birth")
    private Date dateOfBirth;

    @Column(name = "delivery_address", columnDefinition = "NVARCHAR(255)")
    private String deliveryAddress;

    @Column(name = "avatar")
    private String avatar;
}
