import 'package:flutter/material.dart';
import 'login_page.dart'; // untuk logout kembali ke login
import 'product_page.dart';
import 'profil_page.dart';
import 'order_history_page.dart';
import 'deposit_balance_page.dart';  // Import halaman untuk deposit saldo

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            const Text(
              "Saldo Anda: Rp 1,500,000", // Saldo sementara, ganti dengan data dinamis
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
