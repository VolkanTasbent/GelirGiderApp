import 'package:flutter/material.dart';
import 'package:mobilodev6/home_page.dart';
import 'package:mobilodev6/kayit_ol_sayfasi.dart';
import 'database_helper.dart';

class GirisYapSayfasi extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  GirisYapSayfasi({super.key});

  Future<void> girisYap(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen kullanıcı adı ve parolayı girin!")),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUserByUsernameAndPassword(username, password);
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(username: username),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı adı veya parola hatalı!")),
        );
      }
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
          'Giriş Yap',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Kullanıcı Adı', fillColor: Colors.blue),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Parola'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => girisYap(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KayitOlSayfasi())),
              child: const Text('Kayıt Olun'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
