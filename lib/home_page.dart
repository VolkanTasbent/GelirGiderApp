import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobilodev6/ayarlar.dart';
import 'package:mobilodev6/gelir_gider_ekleme.dart';
import 'package:mobilodev6/listeleme.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  int? userId; // Kullanıcı ID
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);

    _loadUserData(); // Kullanıcı verilerini yükle
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData(); // Kullanıcı ve finansal verileri tekrar yükle
  }

  Future<void> _loadUserData() async {
    final dbHelper = DatabaseHelper();
    final user = await dbHelper.getUserDetails(widget.username);
    if (user != null) {
      setState(() {
        userId = user['id'];
      });

      // Gelir, gider ve işlemleri yükle
      _loadFinancialData();
    }
  }

  Future<void> _loadFinancialData() async {
    if (userId == null) return;
    final dbHelper = DatabaseHelper();

    // Gelir ve gider toplamlarını al
    final income = await dbHelper.getTotalIncome(userId!);
    final expense = await dbHelper.getTotalExpense(userId!);

    // İşlemleri al
    final userTransactions = await dbHelper.getTransactionsByUserId(userId!);

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      transactions = userTransactions;
    });
  }

  Future<Map<String, double>> fetchIncomeAndExpense(int userId) async {
    final dbHelper = DatabaseHelper();
    final totalIncome = await dbHelper.getTotalIncome(userId);
    final totalExpense = await dbHelper.getTotalExpense(userId);
    return {'income': totalIncome, 'expense': totalExpense};
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(int userId) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getTransactionsByUserId(userId);
  }

  Future<Map<String, dynamic>?> fetchUserDetails() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getUserDetails(widget.username);
  }

  void _showProfileImageDialog(Uint8List photo) {
    if (_controller.isAnimating) return; // Zaten bir animasyon çalışıyorsa işlem yapma
    _controller.forward(); // Animasyonu başlat

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            // Arka planın yavaşça belirmesi
            FadeTransition(
              opacity: _opacityAnimation,
              child: GestureDetector(
                onTap: () {
                  _controller.reverse();
                  Navigator.pop(context);
                },
                child: Container(color: Colors.black.withOpacity(0.8)),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {
                    _controller.reverse();
                    Navigator.pop(context);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500), // Ekstra efekt süresi
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Image.memory(photo, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (_controller.isAnimating) _controller.reverse(); // Animasyonu geri sar
    });
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4.0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: AppBar(
            backgroundColor: Colors.blue,
            automaticallyImplyLeading: false,
            flexibleSpace: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          await _loadUserData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Veriler güncellendi."),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const Text(
                    'Ana Sayfa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      PopMenu(userId: userId, widget: widget),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Kullanıcı bilgileri yüklenemedi.'));
          }

          final user = snapshot.data!;
          final int userId = user['id'];
          final Uint8List? photo = user['photo'];
          final String companyName = user['company_name'] ?? 'Şirket Adı Yok';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profil Bilgileri
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (photo != null)
                        GestureDetector(
                          onTap: () {
                            _showProfileImageDialog(photo);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0), // Kare için düşük radius
                            child: Image.memory(
                              photo,
                              width: 80.0, // Boyutları kare olacak şekilde ayarlayın
                              height: 80.0,
                              fit: BoxFit.cover, // Görüntüyü sığdırma şekli
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Hoş geldiniz, $companyName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 200),

                // Gelir ve Gider Özeti
                FutureBuilder<Map<String, double>>(
                  future: fetchIncomeAndExpense(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('Gelir ve Gider verileri alınamadı.');
                    }

                    final income = snapshot.data!['income']!;
                    final expense = snapshot.data!['expense']!;

                    return Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryCard("Gelir", "₺${income.toStringAsFixed(2)}", Colors.blue),
                          _buildSummaryCard("Gider", "₺${expense.toStringAsFixed(2)}", Colors.blue),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PopMenu extends StatelessWidget {
  const PopMenu({
    super.key,
    required this.userId,
    required this.widget,
  });

  final int? userId;
  final HomePage widget;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'Gelir-Gider Girişi':
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => GelirGiderEklemeSayfasi(userId: userId ?? -1)));
            break;
          case 'Gelir-Gider Hesaplama':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GelirGiderListesiSayfasi()),
            );
            break;
          case 'Ayarlar':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AyarlarSayfasi(
                  username: widget.username,
                ),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Gelir-Gider Girişi', child: Text('Gelir-Gider Girişi')),
        const PopupMenuItem(value: 'Gelir-Gider Hesaplama', child: Text('Gelir-Gider Hesaplama')),
        const PopupMenuItem(value: 'Ayarlar', child: Text('Ayarlar')),
      ],
    );
  }
}
