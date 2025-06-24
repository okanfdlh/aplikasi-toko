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

class _ProductPageState extends State<ProductPage> with TickerProviderStateMixin {
  List products = [];
  List filteredProducts = [];
  List<String> categories = [];
  String selectedCategory = 'Semua';
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    loadCart();
    fetchProducts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  Future<void> saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartString = json.encode(cart);
    await prefs.setString('cart', cartString);
  }

  Future<void> fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
<<<<<<< HEAD
        Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/getProduct'),
=======
        Uri.parse('http://127.0.0.1:8000/api/getProduct'),
>>>>>>> a114f03 (update)
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

        _animationController.forward(); // mulai animasi
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

    saveCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} ditambahkan ke keranjang')),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Daftar Produk'),
      backgroundColor: Colors.cyan[100],
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (cart.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
                    saveCart();
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
        : SafeArea(
        child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => filterByCategory(cat),
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(
                        color: selectedCategory == cat ? Colors.white : Colors.black,
                      ),
                      backgroundColor: Colors.grey.shade200,
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final imageUrl = product['image'] != null
                        ? 'http://10.0.2.2:8000/storage/products/${product['image']}'
                        : null;

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval((index / filteredProducts.length), 1.0, curve: Curves.easeOut),
                      )),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: imageUrl != null
                                    ? Image.network(
                                        imageUrl,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Tanpa Nama',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${product['price']}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Stok: ${product['stock']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      product['category']?['name'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => addToCart(product),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                                        label: const Text('Keranjang', style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
  )
  );
}
}
