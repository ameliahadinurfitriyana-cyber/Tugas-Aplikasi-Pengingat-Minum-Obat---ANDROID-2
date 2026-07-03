import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medicine_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MediCare Reminder',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.medical_services_rounded,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const SizedBox(height: 12),
        const Text(
          'MediCare Reminder adalah aplikasi pengingat minum obat offline modern yang membantu Anda menjadwalkan obat, melacak kepatuhan, dan mencatat riwayat konsumsi harian Anda secara mandiri dan aman.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Preferensi
              _buildSectionHeader(theme, 'Preferensi Tampilan'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Mode Gelap (Dark Mode)'),
                      subtitle: const Text('Gunakan tema gelap untuk kenyamanan mata'),
                      value: provider.isDarkMode,
                      secondary: const Icon(Icons.dark_mode_rounded),
                      onChanged: (val) {
                        provider.toggleDarkMode(val);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Notifikasi Pengingat'),
                      subtitle: const Text('Aktifkan pengingat minum obat otomatis'),
                      value: provider.notificationsEnabled,
                      secondary: const Icon(Icons.notifications_active_rounded),
                      onChanged: (val) {
                        provider.toggleNotifications(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Database & Backup
              _buildSectionHeader(theme, 'Pencadangan Data (Offline)'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_rounded),
                      title: const Text('Cadangkan Database'),
                      subtitle: const Text('Ekspor data obat & riwayat ke memori lokal'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () async {
                        final backupPath = await provider.backupDatabase();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                backupPath != null
                                    ? 'Cadangkan berhasil! Disimpan di:\n$backupPath'
                                    : 'Gagal mencadangkan database.',
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.settings_backup_restore_rounded),
                      title: const Text('Puluhkan Database'),
                      subtitle: const Text('Impor data dari cadangan lokal terakhir'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () async {
                        // Confirm restore
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Puluhkan Data?'),
                            content: const Text('Tindakan ini akan menimpa data saat ini dengan data cadangan terakhir. Lanjutkan?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  final ok = await provider.restoreDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Database berhasil dipulihkan.'
                                              : 'Tidak ditemukan file cadangan database.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Puluhkan'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tentang Aplikasi
              _buildSectionHeader(theme, 'Informasi Aplikasi'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Tentang MediCare Reminder'),
                      subtitle: const Text('Detail dan deskripsi pengembang'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.developer_board_rounded),
                      title: const Text('Versi Aplikasi'),
                      trailing: const Text(
                        'v1.0.0',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}
