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

  // Memuat riwayat deposit
  Future<void> _loadDepositHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? customerId = prefs.getInt('customer_id'); // Ganti sesuai key yg kamu pakai
      if (customerId == null) {
        print('Customer ID tidak ditemukan di SharedPreferences');
        throw Exception('Customer ID tidak ditemukan');
      }
      print('Customer ID: $customerId');
      setState(() {
        _depositHistory = getDepositHistory(customerId);
      });
    } catch (e) {
      print('Error saat memuat deposit history: $e');
    }
  }

  // Fungsi untuk mendapatkan token dari SharedPreferences
  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      print('Token tidak ditemukan di SharedPreferences');
      return '';
    }
    print('Token: $token');
    return token;
  }

  // Fungsi untuk mendapatkan riwayat deposit
  Future<List<Map<String, dynamic>>> getDepositHistory(int customerId) async {
  String token = await getToken();

  if (token.isEmpty) {
    throw Exception('Token tidak ditemukan');
  }

  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/deposits/$customerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json', // Penting agar Laravel tidak redirect
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);

      if (jsonResponse['data'] is List) {
        List<Map<String, dynamic>> depositHistory =
            List<Map<String, dynamic>>.from(jsonResponse['data']);
        return depositHistory;
      } else {
        throw Exception('Format data tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat riwayat deposit: ${response.statusCode}');
    }
  } catch (e) {
    print('Error saat fetch data deposit: $e');
    rethrow;
  }
}
IconData _getStatusIcon(String status) {
  switch (status) {
    case 'approved':
      return Icons.check_circle;
    case 'pending':
      return Icons.hourglass_empty;
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
          } else if (snapshot.hasData) {
            List<Map<String, dynamic>> depositHistory = snapshot.data!;
            return ListView.builder(
              itemCount: depositHistory.length,
              itemBuilder: (context, index) {
                var deposit = depositHistory[index];

                String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                    .format(DateTime.parse(deposit['created_at']));

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text("Jumlah: Rp ${deposit['amount']}"),
                    subtitle: Text("Tanggal: $formattedDate"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(deposit['status']),
                          color: _getStatusColor(deposit['status']),
                        ),
                        const SizedBox(width: 4),
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
            return const Center(child: Text("Tidak ada riwayat deposit"));
          }
        },
      ),
    );
  }
}
