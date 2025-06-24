// Tambahan package untuk animasi fade (tidak perlu install baru, ini default Flutter)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'product_page.dart';
import 'profil_page.dart';
import 'order_history_page.dart';
import 'deposit_balance_page.dart';
import 'deposit_history_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<double> getSaldo(int customerId) async {
    String token = await getToken();

    if (token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
<<<<<<< HEAD
      Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/customer/$customerId/saldo'),
=======
      Uri.parse('http://127.0.0.1:8000/api/customer/$customerId/saldo'),
>>>>>>> a114f03 (update)
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return double.parse(data['saldo'].toString());
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
              Navigator.pop(context);
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

  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context) {
    final int customerId = 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[100],
        title: const Text("Toko Sembako"),
        leading: Hero(
          tag: 'profileIcon',
          child: IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () => _navigateFade(context, const ProfilePage()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<double>(
              future: getSaldo(customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else if (snapshot.hasData) {
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      color: Colors.cyan[100],
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_rounded,
                            size: 40, color: Colors.cyan),
                        title: const Text("Saldo Anda", style: TextStyle(fontSize: 16)),
                        subtitle: Text(
                          formatRupiah(snapshot.data!),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _navigateFade(context, const DepositBalancePage()),
                          icon: const Icon(Icons.add),
                          label: const Text("Top Up"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[500],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Text("Saldo tidak ditemukan");
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildAnimatedTile(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Pesan Barang',
                    color: Colors.blue,
                    destination: const ProductPage(),
                  ),
                  _buildAnimatedTile(
                    context,
                    icon: Icons.history,
                    label: 'Riwayat Order',
                    color: Colors.deepOrange,
                    destination: const OrderHistoryPage(),
                  ),
                  _buildAnimatedTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Riwayat Deposit',
                    color: Colors.teal,
                    destination: const DepositHistoryPage(),
                  ),
                  _buildAnimatedTile(
                    context,
                    icon: Icons.person,
                    label: 'Profil',
                    color: Colors.purple,
                    destination: const ProfilePage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTile(BuildContext context,
      {required IconData icon, required String label, required Color color, required Widget destination}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.white,
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateFade(context, destination),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      radius: 30,
                      child: Icon(icon, size: 30, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateFade(BuildContext context, Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: 0.0, end: 1.0);
        final fadeAnimation = animation.drive(tween);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }
}
