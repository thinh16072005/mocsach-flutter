package com.mocsach.auth.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail-from}")
    private String mailFrom;

    @Async
    public void sendActivationEmail(String toEmail, String activationCode) {
        String subject = "Kích hoạt tài khoản BookStore - Mã OTP";
        String body = "<h3>Cảm ơn bạn đã đăng ký BookStore!</h3>"
                + "<p>Mã OTP kích hoạt tài khoản của bạn là:</p>"
                + "<h2 style='color: #4F46E5; font-size: 24px; letter-spacing: 2px;'>" + activationCode + "</h2>"
                + "<p>Vui lòng nhập mã này trên ứng dụng để hoàn tất việc đăng ký.</p>";
        sendHtmlEmail(toEmail, subject, body);
    }

    @Async
    public void sendForgotPasswordEmail(String toEmail, String tempPassword) {
        String subject = "Mật khẩu tạm thời - BookStore";
        String body = "Mật khẩu tạm thời của bạn là: <strong>" + tempPassword + "</strong>"
                + "<br/>Vui lòng đăng nhập và đổi mật khẩu ngay.";
        sendHtmlEmail(toEmail, subject, body);
    }

    private void sendHtmlEmail(String to, String subject, String htmlBody) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(mailFrom);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlBody, true);
            mailSender.send(message);
            log.info("Email sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send email to {}: {}", to, e.getMessage());
        }
    }
}
