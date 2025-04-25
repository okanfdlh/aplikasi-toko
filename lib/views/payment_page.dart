import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final int total;

  const PaymentPage({super.key, required this.cart, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Pembayaran")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Total yang harus dibayar: Rp $total"),
            // Tambahkan form nama, metode pembayaran, dll.
          ],
        ),
      ),
    );
  }
}

