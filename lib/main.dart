import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'giris_yap_sayfasi.dart';

void main() {
  runApp(const MyApp());

  Future<void> printDatabasePath() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    print('Database Path: $path');
  }

  printDatabasePath(); // Veritabanı yolunu yazdırmak için çağırılıyor
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobil Programlama Ödev 5',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GirisYapSayfasi(),
    );
  }
}
