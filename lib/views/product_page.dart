import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cart_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List products = [];
  List filteredProducts = [];
  List<String> categories = [];
  String selectedCategory = 'Semua';
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCart();
    fetchProducts();
  }

  // Fungsi untuk mengambil cart dari SharedPreferences
  Future<void> loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartString = prefs.getString('cart');
    if (cartString != null) {
      List<dynamic> decodedCart = json.decode(cartString);
      setState(() {
        cart = decodedCart.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  // Fungsi untuk menyimpan cart ke SharedPreferences
  Future<void> saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartString = json.encode(cart);
    await prefs.setString('cart', cartString);
  }

  // Mengambil data produk dari API
  Future<void> fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/getProduct'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List allProducts = data['data'];
        Set<String> categoryNames = {
          for (var p in allProducts)
            if (p['category'] != null) p['category']['name']
        };

        setState(() {
          products = allProducts;
          filteredProducts = allProducts;
          categories = ['Semua', ...categoryNames];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil produk');
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Filter produk berdasarkan kategori
  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'Semua') {
        filteredProducts = products;
      } else {
        filteredProducts = products
            .where((p) => p['category'] != null && p['category']['name'] == category)
            .toList();
      }
    });
  }

  // Menambahkan produk ke keranjang
  void addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = cart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex != -1) {
        cart[existingIndex]['qty'] += 1;
      } else {
        cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'qty': 1,
        });
      }
    });

    saveCart(); // Simpan keranjang ke SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} ditambahkan ke keranjang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Lihat Keranjang (${cart.length})',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(
                    cart: cart,
                    onCartUpdate: (updatedCart) {
                      setState(() {
                        cart = updatedCart;
                      });
                      saveCart(); // Simpan perubahan keranjang setelah update
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) filterByCategory(value);
                    },
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(product['name'] ?? 'Tanpa Nama'),
                          subtitle: Text(
                              'Stok: ${product['stock']} | Kategori: ${product['category']['name']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Rp ${product['price']}'),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => addToCart(product),
                                child: const Text('+ Keranjang'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
