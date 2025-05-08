import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';  // Ganti dengan halaman login Anda

class DepositBalancePage extends StatefulWidget {
  const DepositBalancePage({super.key});

  @override
  _DepositBalancePageState createState() => _DepositBalancePageState();
}

class _DepositBalancePageState extends State<DepositBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _proofFile; // Menyimpan file bukti transfer

  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk memilih gambar bukti transfer dari galeri atau kamera
  Future<void> _pickProof() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Bisa ganti source ke kamera (ImageSource.camera)
    if (pickedFile != null) {
      setState(() {
        _proofFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk mengupload deposit beserta bukti transfer
  Future<void> _uploadProof() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan jumlah yang valid")),
      );
      return;
    }

    // Ambil token yang disimpan di SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("Token yang diambil: $token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login terlebih dahulu")),
      );
      return;
    }

    final customerId = 1; // Ganti dengan ID customer yang aktif

    // Membuat request untuk deposit
    final url = Uri.parse('http://127.0.0.1:8000/api/customers/$customerId/deposit');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['amount'] = amount.toString()
      ..fields['note'] = _noteController.text;

    if (_proofFile != null) {
      final mimeType = _proofFile!.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'pdf'].contains(mimeType)) {
        // Memastikan file sesuai dengan format yang diterima
        request.files.add(await http.MultipartFile.fromPath('proof', _proofFile!.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File harus berupa gambar atau PDF")),
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bukti transfer harus diunggah")),
      );
      return;
    }

    final response = await request.send();

    if (response.statusCode == 302) {
      // Redirect terjadi, arahkan pengguna ke halaman login
      print("Token tidak valid atau kadaluarsa. Arahkan ke login.");
      // _navigateToLoginPage();
    } else if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final json = jsonDecode(responseBody);
      print("Sukses: ${json['message']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json['message'])),
      );
    } else {
      print("Gagal: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menambahkan saldo")),
      );
    }
  }

  // Fungsi untuk mengarahkan pengguna ke halaman login
  // void _navigateToLoginPage() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => LoginPage()), // Ganti LoginPage dengan halaman login Anda
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deposit Saldo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Jumlah Deposit"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: "Catatan (Opsional)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickProof, // Pilih gambar bukti transfer
              child: const Text("Pilih Bukti Top-up"),
            ),
            if (_proofFile != null)
              Image.file(
                _proofFile!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _uploadProof,
              child: const Text("Unggah Bukti Top-up"),
            ),
          ],
        ),
      ),
    );
  }
}
