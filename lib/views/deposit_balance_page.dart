import 'package:flutter/material.dart';

class DepositBalancePage extends StatefulWidget {
  const DepositBalancePage({super.key});

  @override
  _DepositBalancePageState createState() => _DepositBalancePageState();
}

class _DepositBalancePageState extends State<DepositBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Simulasi pengunggahan bukti top-up
  void _uploadProof() {
    // Lakukan pengiriman data ke API Laravel
    // Misalnya: amount, note, dan file bukti
    print('Bukti top-up berhasil diunggah');
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
