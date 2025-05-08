import 'dart:convert';
import 'dart:io';
import 'home_page.dart';
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
  File? _bukti_pembayaran;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
  }

  Future<void> _loadCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerId = prefs.getInt('customer_id');
      _name = prefs.getString('name') ?? 'Nama tidak ditemukan';
    });
    print("Customer ID: $_customerId, name: $_name");
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

  bool _isStockSufficient(List<Map<String, dynamic>> cartItems, Map<int, int> stockData) {
    for (var item in cartItems) {
      int productId = item['id'];
      int qty = item['qty'];
      if (stockData.containsKey(productId)) {
        if (qty > stockData[productId]!) {
          return false;
        }
      } else {
        return false; // produk tidak ditemukan di stok
      }
    }
    return true;
  }

  Future<Map<int, int>> _fetchStockData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/getProduct'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final List<dynamic> data = responseJson['data'];

      return {
        for (var product in data)
          product['id'] as int: product['stock'] as int,
      };
    } else {
      throw Exception('Gagal mengambil data stok dari server');
    }
  }

Future<void> _submitOrder() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      final stockData = await _fetchStockData();
      print("Stock Data: $stockData");

      if (!_isStockSufficient(widget.cart, stockData)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok produk tidak mencukupi.")),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print("Token: $token");

      final uri = Uri.parse('http://127.0.0.1:8000/api/order');
      var request = http.MultipartRequest('POST', uri)
        ..fields['id_customer'] = _customerId.toString()
        ..fields['alamat'] = _addressController.text
        ..fields['total_item'] = widget.cart.length.toString()
        ..fields['transaction_time'] = DateTime.now().toIso8601String()
        ..fields['status'] = 'pending'
        ..headers['Authorization'] = 'Bearer $token';

      // Pastikan bukti pembayaran ada
      if (_bukti_pembayaran == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan pilih bukti pembayaran")),
        );
        return;
      }

      var paymentFile = await http.MultipartFile.fromPath(
        'bukti_pembayaran',
        _bukti_pembayaran!.path,
      );
      request.files.add(paymentFile);

      // Handle cart with dynamic keys and values
      List<Map<String, String>> products = widget.cart.map((product) {
        // Safely cast values to String, ensuring fields are not null
        return {
          'id_product': product['id']?.toString() ?? '',
          'quantity': product['qty']?.toString() ?? '',
          'price': product['price']?.toString() ?? '',
        };
      }).toList();

      // Ensure there are valid products (no empty fields)
      products.removeWhere((product) {
  final id = product['id_product']?.toString();
  final qty = product['quantity']?.toString();
  final price = product['price']?.toString();

  return id == null || id.isEmpty || 
         qty == null || qty.isEmpty || 
         price == null || price.isEmpty;
});


      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada produk yang valid untuk dipesan.")),
        );
        return;
      }

      // Pass products data as JSON-encoded string
      request.fields['products'] = jsonEncode(products);

      print("Request Body: ${request.fields}");

      final response = await request.send();
      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 201) {
        await _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order berhasil dibuat')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        final responseString = await response.stream.bytesToString();
        print("Response Body: $responseString");
        String errorMessage = 'Gagal membuat order';
        try {
          final responseJson = jsonDecode(responseString);
          if (responseJson['error'] != null) {
            errorMessage = responseJson['error'];
          } else if (responseJson['message'] != null) {
            errorMessage = responseJson['message'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}")),
      );
      print("Error: ${e.toString()}");
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Pembayaran")),
      body: _customerId == null || _name == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
    );
  }
}
