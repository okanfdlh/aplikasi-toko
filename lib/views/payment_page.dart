import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int total;

  const PaymentPage({super.key, required this.cart, required this.total});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  String? _paymentMethod;
  String? _customerName;
  int? _customerId;
  File? _paymentProof; // untuk bukti pembayaran dari lokal file

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerName = prefs.getString('customer_name'); // Sesuaikan key preference login kamu
      _customerId = prefs.getInt('customer_id');
    });
  }

  Future<void> _pickPaymentProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _paymentProof = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_customerId == null || _customerName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data customer tidak ditemukan. Silakan login ulang.')),
        );
        return;
      }

      // Build the payload
      final orderData = {
        'id_customer': _customerId,
        'nama_customer': _customerName,
        'alamat': _addressController.text,
        'bukti_pembayaran': _paymentProof?.path ?? '', // cukup kirim path local
        'total_item': widget.cart.length,
        'transaction_time': DateTime.now().toIso8601String(),
        'products': widget.cart.map((item) => {
          'id_product': item['id_product'],
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order berhasil dibuat')),
        );
        Navigator.pop(context); // kembali ke halaman sebelumnya
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat order')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Pembayaran")),
      body: _customerName == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Total yang harus dibayar: Rp ${widget.total}"),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          enabled: false,
                          initialValue: _customerName,
                          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Alamat Pengiriman'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          hint: const Text('Pilih Metode Pembayaran'),
                          onChanged: (newValue) {
                            setState(() {
                              _paymentMethod = newValue;
                            });
                          },
                          items: ['Cash', 'Card', 'QR Code']
                              .map((paymentMethod) => DropdownMenuItem(
                                    value: paymentMethod,
                                    child: Text(paymentMethod),
                                  ))
                              .toList(),
                          validator: (value) {
                            if (value == null) {
                              return 'Pilih metode pembayaran';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _pickPaymentProof,
                              child: const Text('Pilih Bukti Pembayaran'),
                            ),
                            const SizedBox(width: 10),
                            if (_paymentProof != null) 
                              Text('Bukti terpilih', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitOrder,
                          child: const Text('Kirim Order'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
