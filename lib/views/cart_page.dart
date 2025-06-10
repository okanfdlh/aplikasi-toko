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

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> localCart = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    loadCart();
  }

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

  Future<void> saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartString = json.encode(localCart);
    await prefs.setString('cart', cartString);
  }

  void updateQty(int index, int delta) {
    setState(() {
      localCart[index]['qty'] += delta;
      if (localCart[index]['qty'] <= 0) {
        removeItem(index);
      }
    });
    saveCart();
    widget.onCartUpdate(localCart);
  }

  void removeItem(int index) {
    final removedItem = localCart[index];
    setState(() {
      localCart.removeAt(index);
    });
    saveCart();
    widget.onCartUpdate(localCart);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildCartItem(removedItem, index, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  int getTotalPrice() {
    return localCart.fold(0, (total, item) =>
        total + (item['price'] as int) * (item['qty'] as int));
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

  Widget _buildCartItem(Map<String, dynamic> item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag, size: 32, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Harga: Rp ${item['price']}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => updateQty(index, -1),
                  ),
                  Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => updateQty(index, 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removeItem(index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang'),
      backgroundColor: Colors.cyan[100],),
      body: localCart.isEmpty
          ? const Center(child: Text('Keranjang kosong', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: localCart.length,
                    itemBuilder: (context, index, animation) {
                      final item = localCart[index];
                      return _buildCartItem(item, index, animation);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
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
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
