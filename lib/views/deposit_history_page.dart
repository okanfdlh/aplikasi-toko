import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DepositHistoryPage extends StatefulWidget {
  const DepositHistoryPage({super.key});

  @override
  _DepositHistoryPageState createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  Future<List<Map<String, dynamic>>>? _depositHistory;

  @override
  void initState() {
    super.initState();
    _loadDepositHistory();
  }

  Future<void> _loadDepositHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? customerId = prefs.getInt('customer_id');
      if (customerId == null) throw Exception('Customer ID tidak ditemukan');

      setState(() {
        _depositHistory = getDepositHistory(customerId);
      });
    } catch (e) {
      print('Error saat memuat deposit history: $e');
    }
  }

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<List<Map<String, dynamic>>> getDepositHistory(int customerId) async {
    String token = await getToken();
    if (token.isEmpty) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/deposits/$customerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Gagal memuat riwayat deposit');
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Tidak Diketahui';
    }
  }

  String _formatCurrency(dynamic amount) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  // Pastikan amount adalah num
  final numericAmount = double.tryParse(amount.toString()) ?? 0;
  return formatter.format(numericAmount);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Deposit"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _depositHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> deposits = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: deposits.length,
              itemBuilder: (context, index) {
                final deposit = deposits[index];
                final date = DateFormat('dd MMM yyyy • HH:mm')
                    .format(DateTime.parse(deposit['created_at']));

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(deposit['status']),
                          color: _getStatusColor(deposit['status']),
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(deposit['amount']),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tanggal: $date",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _getStatusLabel(deposit['status']),
                          style: TextStyle(
                            color: _getStatusColor(deposit['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("Tidak ada riwayat deposit."));
          }
        },
      ),
    );
  }
}
