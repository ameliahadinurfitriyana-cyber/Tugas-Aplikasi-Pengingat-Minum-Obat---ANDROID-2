import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedRange = 'Semua'; // 'Semua', 'Hari ini', 'Minggu ini', 'Bulan ini'
  String _selectedStatus = 'Semua'; // 'Semua', 'Taken', 'Skipped', 'Missed'

  final List<String> _rangeOptions = ['Semua', 'Hari ini', 'Minggu ini', 'Bulan ini'];
  
  final Map<String, String> _statusOptions = {
    'Semua': 'Semua Status',
    'Taken': 'Diminum',
    'Skipped': 'Dilewati',
    'Missed': 'Terlewat',
  };

  bool _isWithinRange(String dateStr, String range) {
    if (range == 'Semua') return true;
    
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(date.year, date.month, date.day);

    if (range == 'Hari ini') {
      return logDay.isAtSameMomentAs(today);
    } else if (range == 'Minggu ini') {
      final difference = today.difference(logDay).inDays;
      return difference >= 0 && difference < 7;
    } else if (range == 'Bulan ini') {
      final difference = today.difference(logDay).inDays;
      return difference >= 0 && difference < 30;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Konsumsi Obat'),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          // Filter logs
          final filteredLogs = provider.history.where((log) {
            // Filter by date range
            final matchRange = _isWithinRange(log.date, _selectedRange);
            // Filter by status
            final matchStatus = _selectedStatus == 'Semua' || log.status == _selectedStatus;
            
            return matchRange && matchStatus;
          }).toList();

          return Column(
            children: [
              // Filters Section
              Container(
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Filters
                    Row(
                      children: _rangeOptions.map((range) {
                        final isSelected = _selectedRange == range;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(
                                range,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: theme.primaryColor,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? theme.primaryColor : Colors.grey[300]!,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedRange = range);
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status Filters
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _statusOptions.keys.map((statusKey) {
                          final label = _statusOptions[statusKey]!;
                          final isSelected = _selectedStatus == statusKey;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: theme.primaryColor.withOpacity(0.2),
                              checkmarkColor: theme.primaryColor,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = statusKey;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // History list
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 64,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada riwayat yang ditemukan.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          
                          // Find corresponding medicine and reminder
                          final medicine = provider.medicines.firstWhere(
                            (m) => m.id == log.medicineId,
                            orElse: () => Medicine(
                              name: 'Obat Terhapus',
                              dosage: '',
                              type: '',
                              color: '#9E9E9E',
                              notes: '',
                              stock: 0,
                              startDate: DateTime.now(),
                              endDate: DateTime.now(),
                              createdAt: DateTime.now(),
                            ),
                          );

                          final medColor = Color(
                            int.parse(
                              medicine.color.replaceFirst('#', '0xff'),
                            ),
                          );

                          final dateParsed = DateTime.parse(log.date);
                          final dateFormatted = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dateParsed);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Left colored capsule
                                  Container(
                                    width: 8,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: medColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          medicine.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$dateFormatted • ${DateFormat('HH:mm').format(log.createdAt)}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Badge
                                  _buildStatusBadge(log.status),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'Taken':
        badgeColor = const Color(0xff10b981).withOpacity(0.1);
        textColor = const Color(0xff10b981);
        label = 'Diminum';
        icon = Icons.check_circle_rounded;
        break;
      case 'Skipped':
        badgeColor = const Color(0xffef4444).withOpacity(0.1);
        textColor = const Color(0xffef4444);
        label = 'Dilewati';
        icon = Icons.remove_circle_rounded;
        break;
      case 'Missed':
        badgeColor = const Color(0xffef4444).withOpacity(0.1);
        textColor = const Color(0xffef4444);
        label = 'Terlewat';
        icon = Icons.warning_rounded;
        break;
      default:
        badgeColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Belum';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
