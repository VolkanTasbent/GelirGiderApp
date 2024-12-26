import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class GelirGiderEklemeSayfasi extends StatefulWidget {
  final int userId; // Kullanıcının kimliği

  const GelirGiderEklemeSayfasi({super.key, required this.userId});

  @override
  _GelirGiderEklemeSayfasiState createState() => _GelirGiderEklemeSayfasiState();
}

class _GelirGiderEklemeSayfasiState extends State<GelirGiderEklemeSayfasi> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Gelir'; // Gelir veya Gider
  DateTime _selectedDate = DateTime.now(); // Varsayılan tarih bugünün tarihi
  final _dbHelper = DatabaseHelper();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _kaydet() async {
    String amountText = _amountController.text.trim();
    String description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanları doldurun!')),
      );
      return;
    }

    double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir miktar girin!')),
      );
      return;
    }

    // Kullanıcı kimliği ile işlem ekleme
    await _dbHelper.insertTransaction({
      'type': _selectedType.toLowerCase(), // 'gelir' veya 'gider'
      'amount': amount,
      'description': description,
      'date': _selectedDate.toIso8601String(),
      'user_id': widget.userId, // Kullanıcı kimliği ekleniyor
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_selectedType başarıyla kaydedildi!')),
    );

    // Alanları temizle
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedDate = DateTime.now(); // Tarihi tekrar bugünün tarihine sıfırla
      _selectedType = 'Gelir';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelir/Gider Ekle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarih Seçimi
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gelir/Gider Tipi
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Gelir', 'Gider']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tip', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              // Miktar
              TextField(
                controller: _amountController,
                decoration:
                    const InputDecoration(labelText: 'Miktar', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Açıklama
              TextField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _kaydet,
                child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
