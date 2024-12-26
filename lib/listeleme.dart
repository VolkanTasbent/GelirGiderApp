import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class GelirGiderListesiSayfasi extends StatefulWidget {
  const GelirGiderListesiSayfasi({super.key});

  @override
  _GelirGiderListesiSayfasiState createState() => _GelirGiderListesiSayfasiState();
}

class _GelirGiderListesiSayfasiState extends State<GelirGiderListesiSayfasi> {
  Future<List<Map<String, dynamic>>>? transactions;
  Map<String, int> totals = {'income': 0, 'expense': 0};
  DateTimeRange? selectedDateRange;

  final NumberFormat currencyFormat = NumberFormat.decimalPattern();
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat dateOnlyFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions({DateTimeRange? dateRange}) {
    final dbHelper = DatabaseHelper();

    transactions = dbHelper.database.then((db) {
      String? whereClause;
      List<dynamic>? whereArgs;

      if (dateRange != null) {
        final endOfDay = dateRange.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));

        whereClause = 'date BETWEEN ? AND ?';
        whereArgs = [
          dateRange.start.toIso8601String(),
          endOfDay.toIso8601String(),
        ];
      }

      return db
          .query(
        'transactions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'date DESC',
      )
          .then((data) {
        double incomeTotal = 0;
        double expenseTotal = 0;

        for (var transaction in data) {
          if (transaction['type'] == 'gelir') {
            incomeTotal += (transaction['amount'] as num).toDouble();
          } else if (transaction['type'] == 'gider') {
            expenseTotal += (transaction['amount'] as num).toDouble();
          }
        }

        setState(() {
          totals = {
            'income': incomeTotal.toInt(),
            'expense': expenseTotal.toInt(),
          };
        });

        return data;
      });
    });
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        _loadTransactions(dateRange: picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Center(child: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                selectedDateRange = null;
                _loadTransactions();
              });
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          if (selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Seçilen Tarih Aralığı: ${dateOnlyFormat.format(selectedDateRange!.start)} - ${dateOnlyFormat.format(selectedDateRange!.end)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: transactions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Hiç işlem bulunamadı.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final transaction = snapshot.data![index];
                      final date = DateTime.parse(transaction['date']);
                      final formattedDate = dateFormat.format(date);
                      final amountPrefix = transaction['type'] == 'gelir' ? '+' : '-';

                      return ListTile(
                        title: Text(transaction['description']),
                        subtitle: Text(formattedDate),
                        trailing: Text(
                          '$amountPrefix${currencyFormat.format(transaction['amount'])} ₺',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildStatCard(
                  title: 'Toplam Gelir',
                  value: "+${currencyFormat.format(totals['income'])}",
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  title: 'Toplam Gider',
                  value: "-${currencyFormat.format(totals['expense'])}",
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  title: 'Net Durum',
                  value: ((totals['income'] ?? 0) - (totals['expense'] ?? 0)) >= 0
                      ? "+${currencyFormat.format((totals['income'] ?? 0) - (totals['expense'] ?? 0))}"
                      : "-${currencyFormat.format((totals['expense'] ?? 0) - (totals['income'] ?? 0))}",
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 4,
      color: Colors.blue,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
