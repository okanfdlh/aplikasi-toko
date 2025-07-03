import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class DepositBalancePage extends StatefulWidget {
  const DepositBalancePage({super.key});

  @override
  _DepositBalancePageState createState() => _DepositBalancePageState();
}
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer( // memungkinkan zoom dan geser
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


class _DepositBalancePageState extends State<DepositBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _proofFile;
  final ImagePicker _picker = ImagePicker();

  // Tambahan untuk profil toko
  String? ownerName;
  String? phoneNumber;
  String? logoUrl;

  @override
  void initState() {
    super.initState();
    _fetchStoreProfile();
  }

  Future<void> _fetchStoreProfile() async {
    final response = await http.get(Uri.parse('https://tukokite.shbhosting999.my.id/api/store-profile'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        ownerName = data['owner_name'];
        phoneNumber = data['phone_number'];
        logoUrl = data['logo_url']; // sudah full URL dari Laravel
      });
    } else {
      _showSnackbar('Gagal memuat profil toko');
    }
  }

  Future<void> _pickProof() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _proofFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProof() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackbar("Masukkan jumlah yang valid");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _showSnackbar("Anda harus login terlebih dahulu");
      return;
    }

    final customerId = prefs.getInt('customer_id');

    if (customerId == null) {
      _showSnackbar("Customer ID tidak ditemukan");
      return;
    }

    final url = Uri.parse('https://tukokite.shbhosting999.my.id/api/deposit/$customerId');


    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['amount'] = amount.toString()
      ..fields['note'] = _noteController.text;

    if (_proofFile != null) {
      final mimeType = _proofFile!.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'pdf'].contains(mimeType)) {
        request.files.add(await http.MultipartFile.fromPath('proof', _proofFile!.path));
      } else {
        _showSnackbar("File harus berupa gambar atau PDF");
        return;
      }
    } else {
      _showSnackbar("Bukti transfer harus diunggah");
      return;
    }

    final response = await request.send();

    if (response.statusCode == 302) {
      _navigateToLoginPage();
    } else if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      final json = jsonDecode(responseBody);
      _showSnackbar(json['message']);
    } else {
      _showSnackbar("Gagal menambahkan saldo (${response.statusCode})");
    }
  }

  void _navigateToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.cyan.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deposit Saldo"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (logoUrl != null)
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImagePage(imageUrl: logoUrl!),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      width: 180,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (ownerName != null && phoneNumber != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nama Rekening: $ownerName",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("No Rekening: $phoneNumber", style: const TextStyle(fontSize: 16)),
                  const Divider(height: 30),
                ],
              ),

            Text("Jumlah Deposit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money),
                hintText: "Masukkan jumlah dalam angka",
                filled: true,
                fillColor: Colors.cyan.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            Text("Catatan (Opsional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Contoh: Transfer via BCA",
                filled: true,
                fillColor: Colors.cyan.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: const Text("Pilih Bukti Transfer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
            if (_proofFile != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  _proofFile!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _uploadProof,
              icon: const Icon(Icons.send),
              label: const Text("Unggah Bukti"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
