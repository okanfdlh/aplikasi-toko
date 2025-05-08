import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DepositBalancePage extends StatefulWidget {
  const DepositBalancePage({super.key});

  @override
  _DepositBalancePageState createState() => _DepositBalancePageState();
}

class _DepositBalancePageState extends State<DepositBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Simulasi pengunggahan bukti top-up


void _uploadProof() async {
  final amount = double.tryParse(_amountController.text);
  if (amount == null || amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Masukkan jumlah yang valid")),
    );
    return;
  }

  final customerId = 1; // Ganti dengan ID customer yang aktif
  final url = Uri.parse('http://127.0.0.1:8000/api/customers/$customerId/deposit');

  final response = await http.post(
    url,
    body: {'amount': amount.toString()},
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    print("Sukses: ${json['message']}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(json['message'])),
    );
  } else {
    print("Gagal: ${response.body}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal menambahkan saldo")),
    );
  }
}


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
