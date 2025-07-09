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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? saldo;
  bool isLoadingSaldo = true;

  @override
  void initState() {
    super.initState();
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? customerId = prefs.getInt('customer_id');
      String token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://tukokite.shbhosting999.my.id/api/customer/$customerId/saldo'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          saldo = double.tryParse(data['saldo'].toString()) ?? 0;
          isLoadingSaldo = false;
        });
      } else {
        throw Exception("Gagal mengambil saldo");
      }
    } catch (e) {
      print("Error saldo: $e");
      setState(() {
        isLoadingSaldo = false;
      });
    }
  }

  // Format Rupiah
  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Navigasi dengan reload saat kembali
  Future<void> _navigateAndReload(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _loadSaldo(); // reload saldo setelah kembali
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[100],
        title: const Text("Toko Sembako"),
        leading: Hero(
          tag: 'profileIcon',
          child: IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () => _navigateAndReload(context, const ProfilePage()),
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
            isLoadingSaldo
                ? const CircularProgressIndicator()
                : AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      color: Colors.cyan[100],
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.cyan),
                        title: const Text("Saldo Anda", style: TextStyle(fontSize: 16)),
                        subtitle: Text(
                          formatRupiah(saldo ?? 0),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _navigateAndReload(context, const DepositBalancePage()),
                          icon: const Icon(Icons.add),
                          label: const Text("Top Up"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[500],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildAnimatedTile(context, icon: Icons.shopping_cart, label: 'Pesan Barang', color: Colors.blue, destination: const ProductPage()),
                  _buildAnimatedTile(context, icon: Icons.history, label: 'Riwayat Order', color: Colors.deepOrange, destination: const OrderHistoryPage()),
                  _buildAnimatedTile(context, icon: Icons.account_balance_wallet_outlined, label: 'Riwayat Deposit', color: Colors.teal, destination: const DepositHistoryPage()),
                  _buildAnimatedTile(context, icon: Icons.person, label: 'Profil', color: Colors.purple, destination: const ProfilePage()),
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
              onTap: () => _navigateAndReload(context, destination),
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
