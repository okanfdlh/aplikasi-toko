import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orderHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('customer_id'); // pastikan saat login disimpan
      if (customerId == null) {
        throw Exception("Customer ID tidak ditemukan di SharedPreferences.");
      }

      final url = Uri.parse('http://127.0.0.1:8000/api/order/$customerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> orders = json['data']; // akses data yang benar

      setState(() {
        _orderHistory = orders;
        _isLoading = false;
      });

      } else {
        throw Exception("Gagal mengambil data order.");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.orange;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
Future<void> _updateOrderStatus(int orderId, String newStatus) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('http://127.0.0.1:8000/api/order/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // jika dibutuhkan
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status order berhasil diubah ke "$newStatus".')),
      );
      _fetchOrderHistory(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status order.')),
      );
    }
  } catch (e) {
    print("Error saat mengubah status: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Orderan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderHistory.isEmpty
              ? const Center(child: Text("Belum ada riwayat order."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orderHistory.length,
                  itemBuilder: (context, index) {
                  final order = _orderHistory[index];
                  final orderItems = order['order_items'] as List<dynamic>;
                  final total = orderItems.isNotEmpty ? orderItems[0]['total'] : '0';
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Detail Order ID: ${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                ...orderItems.map<Widget>((item) {
                                final productName = item['product']?['name'] ?? 'Produk tidak ditemukan';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Produk: $productName'),
                                  subtitle: Text('Jumlah: ${item['quantity']} • Harga: Rp${item['price']}'),
                                  trailing: Text('Rp${item['total']}'),
                                );
                              }).toList(),  
                              ],
                            ),
                          );
                        },
                      );
                    },
                      leading: const Icon(Icons.receipt_long, color: Colors.blue),
                      title: Text('ID Order: ${order['id']}'),
                      subtitle: Text('Tanggal: ${order['transaction_time']}\nTotal: Rp$total'),
                      trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order['status'],
                          style: TextStyle(
                            color: _getStatusColor(order['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (order['status'].toLowerCase() != 'selesai')
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content: const Text('Apakah Anda yakin ingin menyelesaikan pesanan ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Tutup dialog
                                        _updateOrderStatus(order['id'], 'selesai'); // Lanjut ubah status
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('Ya, Selesai'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Selesai'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),

                      ],
                    ),

                    ),
                  );
                },

                ),
    );
  }
}
