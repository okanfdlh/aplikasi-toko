import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orderHistory = [];
  bool _isLoading = true;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);

    _fetchOrderHistory();
  }


  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_status_channel',
      'Order Status',
      channelDescription: 'Notifikasi perubahan status orderan',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      title,
      body,
      platformDetails,
    );
  }

  Future<void> _fetchOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('customer_id'); // pastikan saat login disimpan
      if (customerId == null) {
        throw Exception("Customer ID tidak ditemukan di SharedPreferences.");
      }
      final url = Uri.parse('https://tukokite.shbhosting999.my.id/api/order/$customerId');
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
      Uri.parse('https://tukokite.shbhosting999.my.id/api/order/$orderId/status'),
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
      await _showNotification(
        "Status Order Berubah",
        "Pesanan #$orderId telah ditandai sebagai $newStatus.",
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
    appBar: AppBar(
      title: const Text('Riwayat Orderan'),
      backgroundColor: Colors.blueAccent,
      elevation: 0,
    ),
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detail Order #${order['id']}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...orderItems.map<Widget>((item) {
                                    final productName = item['product']?['name'] ?? 'Produk tidak ditemukan';
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                        'Jumlah: ${item['quantity']} • Harga: Rp${item['price']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      trailing: Text(
                                        'Rp${item['total']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Order #${order['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order['status']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order['status'].toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(order['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tanggal: ${order['transaction_time']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: Rp$total',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (order['status'].toLowerCase() != 'selesai')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
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
                                              Navigator.of(context).pop();
                                              _updateOrderStatus(order['id'], 'selesai');
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
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  label: const Text('Tandai Selesai'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
  );
}
}
