import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dotted_border/dotted_border.dart';

import 'home_page.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final int total;

  const PaymentPage({super.key, required this.cart, required this.total});

  @override
  _PaymentPageState createState() => _PaymentPageState();
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
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class PickLocationPage extends StatefulWidget {
  @override
  _PickLocationPageState createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  LatLng _pickedLocation = LatLng(-2.5489, 118.0149);

  void _onTapMap(LatLng point) {
    setState(() {
      _pickedLocation = point;
    });
  }

  void _confirmLocation() {
    Navigator.pop(context, _pickedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Lokasi (OSM)")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: _pickedLocation,
              zoom: 13.0,
              onTap: (tapPosition, point) => _onTapMap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.yourapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _pickedLocation,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text("Gunakan Lokasi Ini"),
            ),
          )
        ],
      ),
    );
  }
}
class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  String? _name;
  int? _customerId;
  File? _bukti_pembayaran;
  String? ownerName;
  String? phoneNumber;
  String? logoUrl;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
    _fetchStoreProfile();
    _requestPermission();
  }
  Future<void> _requestPermission() async {
  // Jika ingin benar-benar menggunakan lokasi saat ini (misal untuk fitur lain)
  // import 'package:geolocator/geolocator.dart'; harus diaktifkan
  // Anda bisa menyesuaikan jika tidak menggunakan lokasi aktif
  // Namun tetap disiapkan agar tidak error
}

  Future<void> _fetchStoreProfile() async {
    try {
      final response = await http.get(Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/store-profile'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          ownerName = data['owner_name'];
          phoneNumber = data['phone_number'];
          logoUrl = data['logo_url'];
        });
      } else {
        print("Gagal memuat profil toko: ${response.body}");
      }
    } catch (e) {
      print("Error mengambil profil toko: $e");
    }
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
    final response = await http.get(Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/getProduct'));
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

      final uri = Uri.parse('https://backend-toko.dev-web2.babelprov.go.id/api/order');
      var request = http.MultipartRequest('POST', uri)
        ..fields['id_customer'] = _customerId.toString()
        ..fields['alamat'] = _addressController.text
        ..fields['total_item'] = widget.cart.length.toString()
        ..fields['transaction_time'] = DateTime.now().toIso8601String()
        ..fields['status'] = 'pending'
        ..headers['Authorization'] = 'Bearer $token';

      // Tambahkan koordinat hanya jika ada
      if (_selectedCoordinates != null) {
        request.fields['latitude'] = _selectedCoordinates!.latitude.toString();
        request.fields['longitude'] = _selectedCoordinates!.longitude.toString();
      }

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

  LatLng? _selectedCoordinates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: Colors.cyan[100],
        elevation: 4,
      ),
      body: _customerId == null || _name == null
          ? const Center(child: CircularProgressIndicator())
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 1.0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi Toko dari API
                    if (logoUrl != null || ownerName != null || phoneNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (logoUrl != null)
                              GestureDetector(
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
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (ownerName != null)
                                Text("Nama Rekening: $ownerName",
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (phoneNumber != null)
                                Text("No Rekening: $phoneNumber"),
                            ],
                          ),
                        ),
                      ),

                    // Total Pembayaran
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, size: 36, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Total Pembayaran:\nRp ${widget.total}",
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Form Input
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Data Pemesan", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          TextFormField(
                            enabled: false,
                            initialValue: _name,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Nama Lengkap',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            readOnly: true,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PickLocationPage()),
                              );
                              if (result != null && result is LatLng) {
                                setState(() {
                                  _selectedCoordinates = result;
                                  _addressController.text = 'Lat: ${result.latitude}, Lng: ${result.longitude}';
                                });
                              }
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.map),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Alamat Pengiriman (klik untuk pilih dari peta)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Silakan pilih lokasi pengiriman dari peta';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          const Text("Bukti Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickPaymentProof,
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              dashPattern: [8, 4],
                              color: Colors.brown,
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _bukti_pembayaran != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _bukti_pembayaran!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.upload_file, color: Colors.brown, size: 40),
                                            const SizedBox(height: 10),
                                            const Text("Klik untuk pilih bukti pembayaran"),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Tombol Submit
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitOrder,
                              icon: const Icon(Icons.send),
                              label: const Text('Kirim Pesanan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
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