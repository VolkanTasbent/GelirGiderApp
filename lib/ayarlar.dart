import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class AyarlarSayfasi extends StatefulWidget {
  final String username;

  const AyarlarSayfasi({super.key, required this.username});

  @override
  _AyarlarSayfasiState createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  Uint8List? _photo;
  final _dbHelper = DatabaseHelper();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = await _dbHelper.getUserDetails(widget.username);
    if (user != null) {
      setState(() {
        _usernameController.text = user['username'] ?? '';
        _passwordController.text = user['password'] ?? '';
        _companyNameController.text = user['company_name'] ?? '';
        _photo = user['photo'];
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserDetails() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String companyName = _companyNameController.text.trim();

    if (username.isEmpty || password.isEmpty || companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun!")),
      );
      return;
    }

    try {
      await _dbHelper.updateUserDetails({
        'username': widget.username, // Mevcut kullanıcı adı
        'new_username': username,
        'password': password,
        'company_name': companyName,
        'photo': _photo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bilgiler başarıyla güncellendi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme hatası: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photo = File(image.path).readAsBytesSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profil Fotoğrafı
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Kare için düşük değer veya 0
                          child: _photo != null
                              ? Image.memory(
                                  _photo!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.add_a_photo, size: 30),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kullanıcı Adı
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                    ),
                    const SizedBox(height: 20),

                    // Parola
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Parola'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    // Şirket Adı
                    TextField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(labelText: 'Şirket Adı'),
                    ),
                    const SizedBox(height: 40),

                    // Güncelle Butonu
                    ElevatedButton(
                      onPressed: _updateUserDetails,
                      child: const Text(
                        'Bilgileri Güncelle',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
