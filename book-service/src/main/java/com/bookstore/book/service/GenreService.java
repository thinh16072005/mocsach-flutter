package com.bookstore.book.service;

import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.entity.Genre;
import com.bookstore.book.repository.GenreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class GenreService {

    private final GenreRepository genreRepository;

    public ApiResponse<List<Genre>> getAllGenres() {
        return ApiResponse.success("OK", genreRepository.findAll());
    }

    public ApiResponse<Genre> createGenre(Map<String, String> payload) {
        String name = payload.get("nameGenre");
        if (name == null || name.isBlank()) return ApiResponse.error("Tên thể loại không được để trống!");
        if (genreRepository.existsByNameGenre(name)) return ApiResponse.error("Thể loại đã tồn tại!");
        Genre genre = Genre.builder().nameGenre(name).build();
        return ApiResponse.success("Tạo thể loại thành công!", genreRepository.save(genre));
    }

    public ApiResponse<Genre> updateGenre(int id, Map<String, String> payload) {
        Genre genre = genreRepository.findById(id).orElse(null);
        if (genre == null) return ApiResponse.error("Thể loại không tồn tại!");
        String name = payload.get("nameGenre");
        if (name != null && !name.isBlank()) genre.setNameGenre(name);
        return ApiResponse.success("Cập nhật thành công!", genreRepository.save(genre));
    }

    public ApiResponse<Void> deleteGenre(int id) {
        if (!genreRepository.existsById(id)) return ApiResponse.error("Thể loại không tồn tại!");
        genreRepository.deleteById(id);
        return ApiResponse.success("Xóa thể loại thành công!");
    }
}
