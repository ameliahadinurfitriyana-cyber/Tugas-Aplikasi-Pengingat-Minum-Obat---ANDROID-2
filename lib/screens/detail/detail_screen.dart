import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/medicine.dart';
import '../../models/reminder.dart';
import '../../providers/medicine_provider.dart';
import '../../services/database_service.dart';
import '../add_medicine/add_medicine_screen.dart';

class DetailScreen extends StatefulWidget {
  final Medicine medicine;

  const DetailScreen({super.key, required this.medicine});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final data = await DatabaseService.instance.getRemindersForMedicine(
        widget.medicine.id!,
      );
      if (mounted) {
        setState(() {
          _reminders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading reminders: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Obat?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${widget.medicine.name} beserta semua jadwal dan riwayatnya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Pop Dialog first
              try {
                await Provider.of<MedicineProvider>(
                  context,
                  listen: false,
                ).deleteMedicine(widget.medicine.id!);
                if (mounted) {
                  Navigator.of(context).pop(); // Pop Detail Page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.medicine.name} berhasil dihapus.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Gagal menghapus obat. $e')),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medColor = Color(
      int.parse(widget.medicine.color.replaceFirst('#', '0xff')),
    );
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Obat'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddMedicineScreen(medicine: widget.medicine),
                    ),
                  )
                  .then((_) {
                    _loadReminders();
                    // Refresh local provider to draw updated details
                    // ignore: use_build_context_synchronously
                    Provider.of<MedicineProvider>(
                      context,
                      listen: false,
                    ).refreshData();
                  });
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                // Fetch latest state of this medicine from provider (in case edited)
                final currentMedIdx = provider.medicines.indexWhere(
                  (m) => m.id == widget.medicine.id,
                );
                if (currentMedIdx == -1) return const SizedBox(); // Was deleted

                final medicine = provider.medicines[currentMedIdx];
                final filteredHistory = provider.history
                    .where((h) => h.medicineId == medicine.id)
                    .toList();

                // Compute adherence rate for this medicine specifically
                double medAdherenceRate = 100.0;
                if (filteredHistory.isNotEmpty) {
                  final takenCount = filteredHistory
                      .where((h) => h.status == 'Taken')
                      .length;
                  medAdherenceRate =
                      (takenCount / filteredHistory.length) * 100;
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header card with medicine name and type icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: medColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: medColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: medColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTypeIcon(medicine.type),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicine.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 24,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${medicine.dosage} • ${medicine.type}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isDark
                                        ? Colors.grey[350]
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stock Section with low stock warning
                    _buildSectionTitle(theme, 'Ketersediaan Stok'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sisa Stok',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${medicine.stock} Dosis',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: medicine.stock <= 5
                                        ? Colors.orange
                                        : theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            if (medicine.stock <= 5) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        medicine.stock == 0
                                            ? 'Stok obat telah habis! Harap isi ulang.'
                                            : 'Stok obat hampir habis! Harap segera isi ulang.',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reminders Section
                    _buildSectionTitle(theme, 'Jadwal Pengingat'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Frekuensi: ${_getRepeatLabel(_reminders.firstOrNull?.repeatType ?? "Every Day")}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (_reminders.firstOrNull?.repeatType ==
                                'Custom') ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 28.0),
                                child: Text(
                                  'Hari: ${_reminders.firstOrNull?.days.join(', ') ?? ''}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Periode: ${DateFormat('dd MMM').format(medicine.startDate)} s/d ${DateFormat('dd MMM yyyy').format(medicine.endDate)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text(
                              'Jam Minum:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _reminders.map((r) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        r.time,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Compliance Adherence Card
                    _buildSectionTitle(theme, 'Riwayat Kepatuhan'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tingkat Kepatuhan',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${medAdherenceRate.toStringAsFixed(0)}%',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getAdherenceColor(medAdherenceRate),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: medAdherenceRate / 100,
                                minHeight: 12,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAdherenceColor(medAdherenceRate),
                                ),
                              ),
                            ),
                            if (filteredHistory.isEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada data riwayat minum obat ini.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ] else ...[
                              const Divider(height: 24),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Catatan Riwayat Terakhir:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredHistory.length > 5
                                    ? 5
                                    : filteredHistory.length,
                                separatorBuilder: (context, idx) =>
                                    const Divider(),
                                itemBuilder: (context, idx) {
                                  final hist = filteredHistory[idx];
                                  final reminder = _reminders.firstWhere(
                                    (r) => r.id == hist.reminderId,
                                    orElse: () => Reminder(
                                      time: '--:--',
                                      repeatType: '',
                                      days: [],
                                      isActive: false,
                                    ),
                                  );

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'dd MMMM yyyy',
                                            ).format(DateTime.parse(hist.date)),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Jam ${reminder.time}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      _buildStatusChip(hist.status),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Notes Section if any notes written
                    if (medicine.notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle(theme, 'Catatan Khusus'),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              medicine.notes,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Tablet':
        return Icons.circle_rounded;
      case 'Kapsul':
        return Icons.album_rounded;
      case 'Sirup':
        return Icons.opacity_rounded;
      case 'Tetes':
        return Icons.water_drop_rounded;
      case 'Suntik':
        return Icons.vaccines_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  String _getRepeatLabel(String repeatType) {
    switch (repeatType) {
      case 'Every Day':
        return 'Setiap Hari';
      case 'Mon-Fri':
        return 'Senin - Jumat';
      case 'Custom':
        return 'Hari Tertentu';
      default:
        return repeatType;
    }
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String label;

    switch (status) {
      case 'Taken':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Diminum';
        break;
      case 'Skipped':
        chipColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Dilewati';
        break;
      case 'Missed':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Terlewat';
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = 'Belum';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
