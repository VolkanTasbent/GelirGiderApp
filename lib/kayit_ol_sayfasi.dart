import 'dart:typed_data'; // Fotoğraf için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Fotoğraf seçimi için
import 'package:mobilodev6/giris_yap_sayfasi.dart';
import 'database_helper.dart';

class KayitOlSayfasi extends StatefulWidget {
  KayitOlSayfasi({super.key});

  @override
  _KayitOlSayfasiState createState() => _KayitOlSayfasiState();
}

class _KayitOlSayfasiState extends State<KayitOlSayfasi> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  Uint8List? _photo; // Fotoğraf

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _photo = imageBytes;
      });
    }
  }

  Future<void> kayitOl(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String companyName = _companyNameController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty || companyName.isEmpty || _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurun ve fotoğraf ekleyin!")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifreler eşleşmiyor!")),
      );
      return;
    }

    final dbHelper = DatabaseHelper();
    try {
      await dbHelper.insertUser({
        'username': username,
        'password': password,
        'company_name': companyName,
        'photo': _photo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı!")),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GirisYapSayfasi()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Kayıt Ol',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Şifre (Tekrar)'),
                obscureText: true,
              ),
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Şirket Adı'),
              ),
              const SizedBox(height: 20),
              _photo == null
                  ? const Text("Fotoğraf seçilmedi.")
                  : Image.memory(_photo!, height: 100, width: 100, fit: BoxFit.cover),
              ElevatedButton(
                onPressed: _pickPhoto,
                child: const Text('Fotoğraf Seç', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => kayitOl(context),
                child: const Text(
                  'Kaydol',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (context) => GirisYapSayfasi()), (Route<dynamic> route) => false),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
