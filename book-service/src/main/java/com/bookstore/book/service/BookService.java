package com.bookstore.book.service;

import com.bookstore.book.dto.request.CreateBookRequest;
import com.bookstore.book.dto.response.ApiResponse;
import com.bookstore.book.dto.response.BookListDto;
import com.bookstore.book.entity.Book;
import com.bookstore.book.entity.Genre;
import com.bookstore.book.entity.Image;
import com.bookstore.book.repository.BookRepository;
import com.bookstore.book.repository.GenreRepository;
import com.bookstore.book.repository.ImageRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookService {

    private final BookRepository bookRepository;
    private final GenreRepository genreRepository;
    private final ImageRepository imageRepository;
    private final CloudinaryService cloudinaryService;

    public ApiResponse<Page<BookListDto>> getBooks(int page, int size, String sort) {
        Pageable pageable = PageRequest.of(page, size, parseSort(sort));
        Page<Book> books = bookRepository.findAll(pageable);
        initImages(books.getContent());
        return ApiResponse.success("OK", books.map(BookListDto::from));
    }

    @Transactional
    public ApiResponse<List<BookListDto>> getBestsellers(int size) {
        int limit = Math.min(Math.max(size, 1), 20);
        Pageable pageable = PageRequest.of(0, limit,
                Sort.by(Sort.Order.desc("soldQuantity"), Sort.Order.desc("avgRating"), Sort.Order.desc("idBook")));
        List<Book> books = bookRepository.findAll(pageable).getContent();
        initImages(books);
        return ApiResponse.success("OK", books.stream().map(BookListDto::from).toList());
    }

    private static void initImages(List<Book> books) {
        books.forEach(b -> {
            if (b.getImages() != null) {
                b.getImages().size();
            }
        });
    }

    private static Sort parseSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return Sort.by(Sort.Direction.DESC, "idBook");
        }
        String[] parts = sort.split(",");
        String field = parts[0].trim();
        boolean asc = parts.length > 1 && "asc".equalsIgnoreCase(parts[1].trim());
        return asc ? Sort.by(field).ascending() : Sort.by(field).descending();
    }

    public ApiResponse<Page<BookListDto>> searchBooks(String name, Integer genreId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Book> result;
        if (name != null && !name.isBlank() && genreId != null) {
            result = bookRepository.findByNameBookContainingIgnoreCaseAndGenres_IdGenre(name, genreId, pageable);
        } else if (name != null && !name.isBlank()) {
            result = bookRepository.findByNameBookContainingIgnoreCase(name, pageable);
        } else if (genreId != null) {
            result = bookRepository.findByGenres_IdGenre(genreId, pageable);
        } else {
            result = bookRepository.findAll(pageable);
        }
        initImages(result.getContent());
        return ApiResponse.success("OK", result.map(BookListDto::from));
    }

    public ApiResponse<Book> getBookById(int id) {
        Book book = bookRepository.findById(id)
                .orElse(null);
        return book != null ? ApiResponse.success("OK", book) : ApiResponse.error("Không tìm thấy sách!");
    }

    @Transactional
    public ApiResponse<Book> createBook(CreateBookRequest request, List<MultipartFile> images) {
        if (request.getNameBook() == null || request.getNameBook().isBlank()) {
            return ApiResponse.error("Tên sách không được để trống!");
        }
        if (request.getListPrice() <= 0) {
            return ApiResponse.error("Giá niêm yết phải lớn hơn 0!");
        }

        List<Genre> genres = resolveGenres(request.getGenreIds());
        if (genres == null) return ApiResponse.error("Có thể loại không tồn tại!");

        Book book = Book.builder()
                .nameBook(request.getNameBook())
                .author(request.getAuthor())
                .description(request.getDescription())
                .listPrice(request.getListPrice())
                .sellPrice(calculateSellPrice(request.getListPrice(), request.getDiscountPercent()))
                .quantity(request.getQuantity())
                .discountPercent(request.getDiscountPercent())
                .avgRating(0.0)
                .soldQuantity(0)
                .genres(genres)
                .build();

        Book saved = bookRepository.save(book);
        saveImages(saved, images);
        log.info("Book created: id={}, name={}", saved.getIdBook(), saved.getNameBook());
        return ApiResponse.success("Tạo sách thành công!", saved);
    }

    @Transactional
    public ApiResponse<Book> updateBook(int id, CreateBookRequest request, List<MultipartFile> newImages,
                                        List<Integer> keepImageIds) {
        Book book = bookRepository.findById(id)
                .orElse(null);
        if (book == null) return ApiResponse.error("Không tìm thấy sách!");

        List<Genre> genres = resolveGenres(request.getGenreIds());
        if (genres == null) return ApiResponse.error("Có thể loại không tồn tại!");

        applyBookUpdates(book, request, genres);
        bookRepository.save(book);

        // Áp dụng thay đổi ảnh khi có ảnh mới HOẶC khi client gửi keepImageIds
        // (để hỗ trợ xóa ảnh cũ mà không cần upload ảnh mới).
        boolean hasNewImages = newImages != null && !newImages.isEmpty();
        if (hasNewImages || keepImageIds != null) {
            handleImageUpdates(book, keepImageIds, newImages != null ? newImages : List.of());
        }

        return ApiResponse.success("Cập nhật sách thành công!", book);
    }

    @Transactional
    public ApiResponse<Void> deleteBook(int id) {
        Book book = bookRepository.findById(id)
                .orElse(null);
        if (book == null) return ApiResponse.error("Không tìm thấy sách!");
        try {
            bookRepository.delete(book);
            return ApiResponse.success("Xóa sách thành công!");
        } catch (Exception e) {
            log.error("Delete book failed: {}", e.getMessage());
            return ApiResponse.error("Không thể xóa sách. Sách có thể đang được sử dụng.");
        }
    }

    public ApiResponse<Void> updateStock(int id, Map<String, Integer> request) {
        Book book = bookRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sách!"));
        int delta = request.getOrDefault("delta", 0);
        book.setQuantity(book.getQuantity() + delta);
        if (delta < 0) {
            book.setSoldQuantity(book.getSoldQuantity() + Math.abs(delta));
        }
        bookRepository.save(book);
        return ApiResponse.success("Cập nhật tồn kho thành công!");
    }

    public ApiResponse<Void> updateAvgRating(int id, Map<String, Double> request) {
        Book book = bookRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy sách!"));
        double newAvg = request.getOrDefault("avgRating", book.getAvgRating());
        book.setAvgRating(newAvg);
        bookRepository.save(book);
        return ApiResponse.success("Cập nhật rating thành công!");
    }

    private double calculateSellPrice(double listPrice, int discountPercent) {
        return listPrice - (listPrice * discountPercent / 100.0);
    }

    private List<Genre> resolveGenres(List<Integer> genreIds) {
        if (genreIds == null || genreIds.isEmpty()) return null;
        List<Genre> genres = new ArrayList<>();
        for (int id : genreIds) {
            Genre genre = genreRepository.findById(id).orElse(null);
            if (genre == null) return null;
            genres.add(genre);
        }
        return genres;
    }

    private void applyBookUpdates(Book book, CreateBookRequest request, List<Genre> genres) {
        book.setNameBook(request.getNameBook());
        book.setAuthor(request.getAuthor());
        book.setDescription(request.getDescription());
        book.setListPrice(request.getListPrice());
        book.setSellPrice(calculateSellPrice(request.getListPrice(), request.getDiscountPercent()));
        book.setQuantity(request.getQuantity());
        book.setDiscountPercent(request.getDiscountPercent());
        book.setGenres(genres);
    }

    private void saveImages(Book book, List<MultipartFile> images) {
        if (images == null || images.isEmpty()) return;
        for (int i = 0; i < images.size(); i++) {
            MultipartFile file = images.get(i);
            if (file.isEmpty()) continue;
            String url = cloudinaryService.uploadImage(file,
                    "Book_" + book.getIdBook() + "_" + i + "_" + System.currentTimeMillis());
            Image image = Image.builder()
                    .book(book)
                    .nameImage(file.getOriginalFilename())
                    .urlImage(url)
                    .thumbnail(i == 0)
                    .build();
            imageRepository.save(image);
        }
    }

    private void handleImageUpdates(Book book, List<Integer> keepImageIds, List<MultipartFile> newImages) {
        List<Image> current = imageRepository.findByBook_IdBook(book.getIdBook());
        if (keepImageIds != null) {
            current.stream()
                    .filter(img -> !keepImageIds.contains(img.getIdImage()))
                    .forEach(imageRepository::delete);
        } else {
            imageRepository.deleteAll(current);
        }
        int keepCount = keepImageIds != null ? keepImageIds.size() : 0;
        for (int i = 0; i < newImages.size(); i++) {
            MultipartFile file = newImages.get(i);
            if (file.isEmpty()) continue;
            String url = cloudinaryService.uploadImage(file,
                    "Book_" + book.getIdBook() + "_" + System.currentTimeMillis() + "_" + i);
            Image image = Image.builder()
                    .book(book)
                    .nameImage(file.getOriginalFilename())
                    .urlImage(url)
                    .thumbnail(keepCount == 0 && i == 0)
                    .build();
            imageRepository.save(image);
        }
    }
}
