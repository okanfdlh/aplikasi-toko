import 'package:flutter/material.dart';

class KeuntunganPage extends StatelessWidget {
  const KeuntunganPage({super.key});

  final List<Map<String, dynamic>> laporanBulanan = const [
    {'bulan': 'Januari', 'keuntungan': 1500000},
    {'bulan': 'Februari', 'keuntungan': 1800000},
    {'bulan': 'Maret', 'keuntungan': 2100000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keuntungan Perbulan")),
      body: ListView.builder(
        itemCount: laporanBulanan.length,
        itemBuilder: (context, index) {
          final item = laporanBulanan[index];
          return ListTile(
            title: Text(item['bulan']),
            trailing: Text("Rp ${item['keuntungan']}"),
          );
        },
      ),
    );
  }
}
