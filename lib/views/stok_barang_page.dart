import 'package:flutter/material.dart';

class StokBarangPage extends StatelessWidget {
  const StokBarangPage({super.key});

  final List<Map<String, dynamic>> dummyStok = const [
    {'nama': 'Kopi Hitam', 'stok': 25},
    {'nama': 'Teh Manis', 'stok': 15},
    {'nama': 'Indomie Goreng', 'stok': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stok Barang")),
      body: ListView.builder(
        itemCount: dummyStok.length,
        itemBuilder: (context, index) {
          final item = dummyStok[index];
          return ListTile(
            title: Text(item['nama']),
            subtitle: Text("Sisa stok: ${item['stok']}"),
          );
        },
      ),
    );
  }
}
