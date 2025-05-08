import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> register() async {
  setState(() => _isLoading = true);
  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/storeCustomer'),
      body: {
        'name': nameController.text,
        'email': emailController.text,
        'phone_number': phoneController.text,
        'password': passwordController.text,
      },
    );

    final data = json.decode(response.body);
    print("DEBUG: Response status code: ${response.statusCode}");
    print("DEBUG: Response body: $data");
    if (response.statusCode == 200 && data['status'] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil!")),
      );

      // Tunggu sebentar agar user lihat snackbar, lalu arahkan ke login
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    

      // Navigator.pop(context);
    } else {
      final errorMessage = data['message'] ?? "Registrasi gagal.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Terjadi kesalahan: $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrasi")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.cyan[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "TOKO SEMBAKO",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // const SizedBox(height: 10),
              // Image.asset(
              //   'assets/toko.png',
              //   width: 100,
              //   height: 100,
              // ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nama',
                  filled: true,
                  fillColor: Colors.yellow[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.yellow[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: 'Nomor Telepon',
                  filled: true,
                  fillColor: Colors.yellow[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.yellow[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 60),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Registrasi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
