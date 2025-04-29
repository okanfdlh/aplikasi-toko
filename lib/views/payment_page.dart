import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  String? _name;
  int? _customerId;
  File? _bukti_pembayaran; // untuk bukti pembayaran dari lokal file

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _customerId = prefs.getInt('customer_id');
    _name = prefs.getString('name') ?? 'Nama tidak ditemukan';
  });

  // Debugging: Check if the data is loaded correctly
  print(" Customer ID: $_customerId,name: $_name");
}



  Future<void> _pickPaymentProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _bukti_pembayaran = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
  if (_formKey.currentState?.validate() ?? false) {
    if (_customerId == null || _name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data customer tidak ditemukan. Silakan login ulang.')),
      );
      return;
    }

    // Retrieve the Bearer token from SharedPreferences or Secure Storage
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');  // For SharedPreferences

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token tidak ditemukan. Silakan login ulang.')),
      );
      return;
    }

    // Build the payload
    final uri = Uri.parse('http://10.0.2.2:8000/api/order');
    var request = http.MultipartRequest('POST', uri)
      ..fields['id_customer'] = _customerId.toString()
      ..fields['alamat'] = _addressController.text
      ..fields['total_item'] = widget.cart.length.toString()
      ..fields['transaction_time'] = DateTime.now().toIso8601String();

    // Add Bearer Token to Authorization Header
    request.headers['Authorization'] = 'Bearer $token';  // Add the token

    // Menambahkan file bukti pembayaran (jika ada)
    if (_bukti_pembayaran != null) {
      var file = await http.MultipartFile.fromPath(
        'bukti_pembayaran', // Sesuaikan dengan nama parameter di API
        _bukti_pembayaran!.path,
      );
      request.files.add(file);
    }

    // Menambahkan produk ke order sebagai array objek
    List<Map<String, String>> products = [];
    for (var item in widget.cart) {
      products.add({
        'id_product': item['id_product'].toString(),
        'quantity': item['qty'].toString(),
        'price': item['price'].toString(),
      });
    }

    // Convert the products list to a JSON string and add it as a field
    request.fields['products'] = jsonEncode(products);

    // Send the request
    final response = await request.send();
    
    if (response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        final redirectResponse = await http.get(Uri.parse(redirectUrl));
        print('Redirect response: ${redirectResponse.body}');
        // You can process the redirect response here if needed, like logging the user in again or handling the redirection
      }
    } else if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order berhasil dibuat')),
      );
      Navigator.pop(context); // kembali ke halaman sebelumnya
    } else {
      // Tampilkan detail dari response untuk debugging
      final responseString = await response.stream.bytesToString();
      print('Error: ${response.statusCode}, Response: $responseString');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat order')),
      );
    }
  }
  print("Cart items: ${widget.cart}");
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Pembayaran")),
      body: _customerId == null || _name == null
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
                          initialValue: _name,
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
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _pickPaymentProof,
                              child: const Text('Pilih Bukti Pembayaran'),
                            ),
                            const SizedBox(width: 10),
                            if (_bukti_pembayaran != null) 
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
