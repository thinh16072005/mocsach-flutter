class CouponModel {
  final int idCoupon;
  final String code;
  final int discountPercent;
  final String expiryDate;
  final bool isActive;
  final bool isUsed;

  CouponModel({
    required this.idCoupon,
    required this.code,
    required this.discountPercent,
    required this.expiryDate,
    required this.isActive,
    required this.isUsed,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      idCoupon: json['idCoupon'] ?? 0,
      code: json['code'] ?? '',
      discountPercent: json['discountPercent'] ?? 0,
      expiryDate: json['expiryDate'] ?? '',
      isActive: json['isActive'] ?? false,
      isUsed: json['isUsed'] ?? false,
    );
  }
}
