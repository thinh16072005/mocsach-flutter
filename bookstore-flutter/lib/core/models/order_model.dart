class OrderModel {
  final int idOrder;
  final String? dateCreated;
  final String deliveryAddress;
  final String phoneNumber;
  final String fullName;
  final double totalPriceProduct;
  final double feeDelivery;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String? note;
  final List<dynamic>? listOrderDetails;

  OrderModel({
    required this.idOrder,
    this.dateCreated,
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.fullName,
    required this.totalPriceProduct,
    required this.feeDelivery,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.note,
    this.listOrderDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      idOrder: json['idOrder'] ?? 0,
      dateCreated: json['dateCreated'],
      deliveryAddress: json['deliveryAddress'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      totalPriceProduct: (json['totalPriceProduct'] ?? 0).toDouble(),
      feeDelivery: (json['feeDelivery'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      note: json['note'],
      listOrderDetails: json['listOrderDetails'],
    );
  }
}
