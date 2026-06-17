package com.bookstore.user.util;

import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.util.Base64;

public class Base64ToMultipartFile implements MultipartFile {

    private final byte[] content;
    private final String name;

    public Base64ToMultipartFile(byte[] content, String name) {
        this.content = content;
        this.name = name;
    }

    public static MultipartFile convert(String base64) {
        String data = base64.contains(",") ? base64.split(",")[1] : base64;
        byte[] bytes = Base64.getDecoder().decode(data);
        return new Base64ToMultipartFile(bytes, "upload.jpg");
    }

    public static boolean isBase64(String value) {
        return value != null && (value.startsWith("data:image") || value.matches("^[A-Za-z0-9+/=]+$"));
    }

    @Override public String getName() { return name; }
    @Override public String getOriginalFilename() { return name; }
    @Override public String getContentType() { return "image/jpeg"; }
    @Override public boolean isEmpty() { return content.length == 0; }
    @Override public long getSize() { return content.length; }
    @Override public byte[] getBytes() { return content; }
    @Override public InputStream getInputStream() { return new ByteArrayInputStream(content); }
    @Override public void transferTo(File dest) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(dest)) {
            fos.write(content);
        }
    }
}
