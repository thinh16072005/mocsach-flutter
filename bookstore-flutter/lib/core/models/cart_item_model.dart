class CartItemModel {
  final int idCartItem;
  final int userId;
  final int bookId;
  int quantity;

  CartItemModel({
    required this.idCartItem,
    required this.userId,
    required this.bookId,
    required this.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      idCartItem: json['idCartItem'] ?? 0,
      userId: json['userId'] ?? 0,
      bookId: json['bookId'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
