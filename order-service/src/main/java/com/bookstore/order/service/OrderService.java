package com.bookstore.order.service;

import com.bookstore.order.client.BookClient;
import com.bookstore.order.dto.request.CreateOrderRequest;
import com.bookstore.order.dto.request.UpdateOrderRequest;
import com.bookstore.order.dto.response.ApiResponse;
import com.bookstore.order.dto.response.BookDTO;
import com.bookstore.order.entity.Delivery;
import com.bookstore.order.entity.Order;
import com.bookstore.order.entity.OrderDetail;
import com.bookstore.order.repository.DeliveryRepository;
import com.bookstore.order.repository.OrderDetailRepository;
import com.bookstore.order.repository.OrderRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.sql.Date;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderDetailRepository orderDetailRepository;
    private final DeliveryRepository deliveryRepository;
    private final CartService cartService;
    private final BookClient bookClient;

    public ApiResponse<List<Order>> getAllOrders() {
        return ApiResponse.success("OK", orderRepository.findAll());
    }

    public ApiResponse<List<Order>> getOrdersByUser(int userId) {
        return ApiResponse.success("OK", orderRepository.findByUserId(userId));
    }

    public ApiResponse<Order> getOrderById(int id) {
        Order order = orderRepository.findById(id).orElse(null);
        return order != null ? ApiResponse.success("OK", order) : ApiResponse.error("Không tìm thấy đơn hàng!");
    }

    @Transactional
    public ApiResponse<Order> createOrder(int userId, CreateOrderRequest request) {
        if (request.getOrderItems() == null || request.getOrderItems().isEmpty()) {
            return ApiResponse.error("Danh sách sản phẩm không được trống!");
        }

        // R3/R4: kiểm tra tồn kho + tính tiền server-side. Giá lấy từ book-service (sellPrice),
        // không tin totals client gửi lên. Lưu lại từng book để tái dùng khi tạo OrderDetail.
        Map<Integer, BookDTO> bookCache = new HashMap<>();
        double totalPriceProduct = 0;
        for (CreateOrderRequest.OrderItemRequest item : request.getOrderItems()) {
            BookDTO book;
            try {
                ApiResponse<BookDTO> resp = bookClient.getBookById(item.getBookId());
                book = resp != null ? resp.getData() : null;
            } catch (Exception e) {
                log.error("Error checking book stock for bookId={}: {}", item.getBookId(), e.getMessage());
                return ApiResponse.error("Không thể kiểm tra tồn kho: " + e.getMessage());
            }
            if (book == null) {
                return ApiResponse.error("Không tìm thấy sách ID: " + item.getBookId());
            }
            if (item.getQuantity() <= 0) {
                return ApiResponse.error("Số lượng sách '" + book.getNameBook() + "' không hợp lệ!");
            }
            if (book.getQuantity() < item.getQuantity()) {
                return ApiResponse.error("Sách '" + book.getNameBook() + "' không đủ số lượng!");
            }
            bookCache.put(item.getBookId(), book);
            totalPriceProduct += book.getSellPrice() * item.getQuantity();
        }

        int deliveryId = request.getDeliveryId() > 0 ? request.getDeliveryId() : 1;
        Delivery delivery = deliveryRepository.findById(deliveryId).orElse(null);
        if (delivery == null) {
            return ApiResponse.error("Phương thức giao hàng không hợp lệ!");
        }
        double feeDelivery = delivery.getFeeDelivery();
        double totalPrice = totalPriceProduct + feeDelivery;

        Order order = Order.builder()
                .userId(userId)
                .dateCreated(Date.valueOf(LocalDate.now()))
                .deliveryAddress(request.getDeliveryAddress())
                .phoneNumber(request.getPhoneNumber())
                .fullName(request.getFullName())
                .note(request.getNote())
                .totalPriceProduct(totalPriceProduct)
                .feeDelivery(feeDelivery)
                .feePayment(0)
                .totalPrice(totalPrice)
                .status("Đang xử lý")
                .paymentStatus(request.getPaymentStatus() != null ? request.getPaymentStatus() : "PENDING")
                .paymentId(request.getPaymentId())
                .deliveryId(delivery.getIdDelivery())
                .build();

        Order savedOrder = orderRepository.save(order);

        // Trừ kho và tạo OrderDetail (giá đã chốt từ book-service)
        for (CreateOrderRequest.OrderItemRequest item : request.getOrderItems()) {
            BookDTO book = bookCache.get(item.getBookId());
            bookClient.updateStock(item.getBookId(), Map.of("delta", -item.getQuantity()));

            OrderDetail detail = OrderDetail.builder()
                    .order(savedOrder)
                    .bookId(item.getBookId())
                    .quantity(item.getQuantity())
                    .price(book.getSellPrice())
                    .reviewed(false)
                    .build();
            orderDetailRepository.save(detail);
        }

        // Xóa giỏ hàng
        cartService.clearCart(userId);

        log.info("Order created: id={}, userId={}", savedOrder.getIdOrder(), userId);
        return ApiResponse.success("Đặt hàng thành công!", savedOrder);
    }

    @Transactional
    public ApiResponse<Order> updateOrderStatus(int orderId, UpdateOrderRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElse(null);
        if (order == null) return ApiResponse.error("Không tìm thấy đơn hàng!");

        // Nếu hủy đơn → hoàn kho
        if ("Bị huỷ".equalsIgnoreCase(request.getStatus())
                && !"Bị huỷ".equalsIgnoreCase(order.getStatus())) {
            List<OrderDetail> details = orderDetailRepository.findByOrder(order);
            for (OrderDetail detail : details) {
                try {
                    bookClient.updateStock(detail.getBookId(), Map.of("delta", detail.getQuantity()));
                } catch (Exception e) {
                    log.error("Failed to restore stock for bookId={}: {}", detail.getBookId(), e.getMessage());
                }
            }
        }

        if (request.getStatus() != null) order.setStatus(request.getStatus());
        if (request.getPaymentStatus() != null) order.setPaymentStatus(request.getPaymentStatus());
        orderRepository.save(order);
        return ApiResponse.success("Cập nhật đơn hàng thành công!", order);
    }
}
