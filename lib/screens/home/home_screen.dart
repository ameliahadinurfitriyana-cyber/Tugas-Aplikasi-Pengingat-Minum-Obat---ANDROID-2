import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../providers/medicine_provider.dart';
import '../add_medicine/add_medicine_screen.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi 👋';
    if (hour < 15) return 'Selamat Siang 👋';
    if (hour < 19) return 'Selamat Sore 👋';
    return 'Selamat Malam 👋';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            final todaySchedules = provider.getSchedulesForDate(DateTime.now());
            final totalMedicines = provider.medicines.length;
            final scheduledToday = todaySchedules.length;
            final takenToday = todaySchedules.where((s) => s.status == 'Taken').length;
            final missedToday = todaySchedules.where((s) => s.status == 'Missed').length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistics Grid Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kepatuhan Hari Ini',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem('Total Obat', '$totalMedicines', Colors.white),
                              _buildStatItem('Jadwal', '$scheduledToday', Colors.white),
                              _buildStatItem('Diminum', '$takenToday', Colors.white),
                              _buildStatItem('Terlewat', '$missedToday', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Title Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadwal Hari Ini',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (scheduledToday > 0)
                          Text(
                            '$takenToday/$scheduledToday Selesai',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Schedule List
                if (todaySchedules.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.spa_rounded,
                              size: 72,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada jadwal untuk hari ini.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan obat untuk memulai pengingat.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = todaySchedules[index];
                        final medColor = Color(
                          int.parse(
                            item.medicine.color.replaceFirst('#', '0xff'),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Slidable(
                            key: ValueKey(item.reminder.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                if (item.status == 'Pending' || item.status == 'Missed') ...[
                                  SlidableAction(
                                    onPressed: (context) {
                                      provider.recordHistory(
                                        item.medicine.id!,
                                        item.reminder.id!,
                                        'Taken',
                                      );
                                    },
                                    backgroundColor: const Color(0xff10b981),
                                    foregroundColor: Colors.white,
                                    icon: Icons.check_circle_outline_rounded,
                                    label: 'Minum',
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(20),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) {
                                      provider.recordHistory(
                                        item.medicine.id!,
                                        item.reminder.id!,
                                        'Skipped',
                                      );
                                    },
                                    backgroundColor: const Color(0xffef4444),
                                    foregroundColor: Colors.white,
                                    icon: Icons.cancel_outlined,
                                    label: 'Lewati',
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(20),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(medicine: item.medicine),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Custom indicator colored container
                                      Container(
                                        width: 12,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: medColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Medicine Text Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.time,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.medicine.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.medicine.dosage} • ${item.medicine.type}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status badge
                                      _buildStatusBadge(context, item.status),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: todaySchedules.length,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Obat'),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
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
      case 'Pending':
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
          Icon(icon, size: 16, color: textColor),
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
