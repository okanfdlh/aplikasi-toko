import 'dart:convert';
import 'package:flutter/material.dart';
import 'login_page.dart'; // untuk logout kembali ke login
import 'product_page.dart';
import 'profil_page.dart';
import 'order_history_page.dart';
import 'deposit_balance_page.dart';
import 'deposit_history_page.dart';  // Import halaman untuk deposit saldo
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Fungsi untuk mendapatkan token dari SharedPreferences
  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? ''; // Mengembalikan token atau string kosong jika tidak ada
  }

  // Fungsi untuk mendapatkan saldo
  Future<double> getSaldo(int customerId) async {
  String token = await getToken();

  if (token.isEmpty) {
    throw Exception('Token tidak ditemukan');
  }

  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/api/customer/$customerId/saldo'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    double saldo = double.parse(data['saldo'].toString()); // Mengonversi saldo menjadi double
    return saldo;
  } else {
    throw Exception('Failed to load saldo');
  }
}

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () {
              Navigator.pop(context); // tutup dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ganti dengan ID pelanggan yang sesuai
    final int customerId = 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Toko Sembako Ida"),
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Profil',
          onPressed: () {
            // Navigasi ke halaman Profil
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Saldo Pengguna
            FutureBuilder<double>(
              future: getSaldo(customerId), // Ambil saldo berdasarkan customerId
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else if (snapshot.hasData) {
                  double saldo = snapshot.data!; // Ambil data saldo yang bertipe double
                  return Text(
                    "Saldo Anda: Rp ${saldo.toStringAsFixed(0)}", // Format saldo
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  );
                } else {
                  return const Text("Saldo tidak ditemukan");
                }
              },
            ),

            const SizedBox(height: 16),
            // Tombol Deposit Saldo
            _buildMenuCard(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Deposit Saldo',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DepositBalancePage()),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Daftar Barang",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              icon: Icons.shopping_bag,
              title: 'Pesan Barang',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              context,
              icon: Icons.history,
              title: 'Riwayat Orderan',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              context,
              icon: Icons.history,
              title: 'Riwayat Deposit',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DepositHistoryPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.green),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
