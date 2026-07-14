class BookModel {
  final int idBook;
  final String nameBook;
  final String author;
  final String? description;
  final double listPrice;
  final double sellPrice;
  final int quantity;
  final double avgRating;
  final int soldQuantity;
  final int discountPercent;
  final bool isDeleted;
  final List<dynamic>? genres;
  final List<dynamic>? images;

  BookModel({
    required this.idBook,
    required this.nameBook,
    required this.author,
    this.description,
    required this.listPrice,
    required this.sellPrice,
    required this.quantity,
    required this.avgRating,
    required this.soldQuantity,
    required this.discountPercent,
    required this.isDeleted,
    this.genres,
    this.images,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      idBook: json['idBook'] ?? 0,
      nameBook: json['nameBook'] ?? '',
      author: json['author'] ?? '',
      description: json['description'],
      listPrice: (json['listPrice'] ?? 0).toDouble(),
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      soldQuantity: json['soldQuantity'] ?? 0,
      discountPercent: json['discountPercent'] ?? 0,
      isDeleted: json['isDeleted'] ?? false,
      genres: json['genres'],
      images: json['images'],
    );
  }

  static String? secureImageUrl(dynamic url) {
    if (url is! String || url.isEmpty) return null;
    return url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
  }

  String? get thumbnailUrl {
    if (images == null || images!.isEmpty) return null;
    final thumb = images!.firstWhere(
      (img) => img['thumbnail'] == true,
      orElse: () => images!.first,
    );
    return secureImageUrl(thumb['urlImage']);
  }
}
