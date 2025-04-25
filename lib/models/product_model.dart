class Product {
  final int id;
  final String nama;
  final int stok;
  final int harga;

  Product({
    required this.id,
    required this.nama,
    required this.stok,
    required this.harga,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nama: json['nama'],
      stok: json['stok'],
      harga: json['harga'],
    );
  }
}
