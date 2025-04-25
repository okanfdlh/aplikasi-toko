import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'payment_page.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) onCartUpdate;

  const CartPage({super.key, required this.cart, required this.onCartUpdate});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> localCart = [];

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  // Fungsi untuk memuat cart dari shared preferences
  Future<void> loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cartString = prefs.getString('cart');
    if (cartString != null) {
      List<dynamic> decodedCart = json.decode(cartString);
      setState(() {
        localCart = decodedCart.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    } else {
      setState(() {
        localCart = List<Map<String, dynamic>>.from(widget.cart);
      });
    }
  }

  // Fungsi untuk menyimpan cart ke shared preferences
  Future<void> saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartString = json.encode(localCart);
    await prefs.setString('cart', cartString);
  }

  void updateQty(int index, int delta) {
    setState(() {
      localCart[index]['qty'] += delta;
      if (localCart[index]['qty'] <= 0) {
        localCart[index]['qty'] = 1;
      }
    });
    saveCart(); // Simpan perubahan cart setelah update qty
    widget.onCartUpdate(localCart);
  }

  void removeItem(int index) {
    setState(() {
      localCart.removeAt(index);
    });
    saveCart(); // Simpan perubahan cart setelah menghapus item
    widget.onCartUpdate(localCart);
  }

  int getTotalPrice() {
    int total = 0;
    for (var item in localCart) {
      int price = (item['price'] as num).toInt();
      int qty = (item['qty'] as int);
      total += price * qty;
    }
    return total;
  }

  void goToPaymentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cart: localCart,
          total: getTotalPrice(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: localCart.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: localCart.length,
                    itemBuilder: (context, index) {
                      final item = localCart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(item['name']),
                          subtitle: Text('Harga: Rp ${item['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => updateQty(index, -1),
                              ),
                              Text('${item['qty']}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => updateQty(index, 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Total Harga: Rp ${getTotalPrice()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: goToPaymentForm,
                        icon: const Icon(Icons.payment),
                        label: const Text('Pesan Sekarang'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
