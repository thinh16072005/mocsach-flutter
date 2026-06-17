package com.bookstore.user.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public String uploadImage(MultipartFile file, String publicId) {
        try {
            Map<?, ?> result = cloudinary.uploader().upload(file.getBytes(),
                    ObjectUtils.asMap("public_id", publicId, "overwrite", true));
            return (String) result.get("secure_url");
        } catch (Exception e) {
            log.error("Cloudinary upload failed: {}", e.getMessage());
            throw new RuntimeException("Upload ảnh thất bại: " + e.getMessage());
        }
    }

    public void deleteImage(String imageUrl) {
        try {
            String publicId = extractPublicId(imageUrl);
            if (publicId != null) {
                cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
            }
        } catch (Exception e) {
            log.warn("Cloudinary delete failed: {}", e.getMessage());
        }
    }

    private String extractPublicId(String imageUrl) {
        if (imageUrl == null || imageUrl.isEmpty()) return null;
        int start = imageUrl.lastIndexOf('/') + 1;
        int end = imageUrl.lastIndexOf('.');
        return end > start ? imageUrl.substring(start, end) : null;
    }
}
