import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Kepatuhan'),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final counts = provider.getHistoryStatusCounts();
          final taken = counts['Taken'] ?? 0;
          final skipped = counts['Skipped'] ?? 0;
          final missed = counts['Missed'] ?? 0;
          final total = taken + skipped + missed;

          final rate = provider.getAdherenceRate();

          // Calculate weekly progress (last 7 days compliance)
          final List<double> weeklyCompliance = [];
          final List<String> weekdayLabels = [];
          final now = DateTime.now();

          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            final scheds = provider.getSchedulesForDate(date);
            
            if (scheds.isEmpty) {
              weeklyCompliance.add(100.0); // Default to 100 if no medicines scheduled
            } else {
              final takenScheds = scheds.where((s) => s.status == 'Taken').length;
              final compRate = (takenScheds / scheds.length) * 100;
              weeklyCompliance.add(compRate);
            }
            weekdayLabels.add(DateFormat('E', 'id_ID').format(date));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Adherence rate card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Rata-rata Kepatuhan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${rate.toStringAsFixed(0)}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getAdherenceColor(rate),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getAdherenceColor(rate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        total == 0 
                            ? 'Belum ada data konsumsi obat.'
                            : 'Berdasarkan $total jadwal obat terdaftar.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pie chart status breakdown
              if (total > 0) ...[
                Text(
                  'Rincian Status Dosis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: taken.toDouble(),
                                  title: taken > 0 ? '${(taken/total*100).toStringAsFixed(0)}%' : '',
                                  color: const Color(0xff10b981),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: skipped.toDouble(),
                                  title: skipped > 0 ? '${(skipped/total*100).toStringAsFixed(0)}%' : '',
                                  color: const Color(0xfff59e0b),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: missed.toDouble(),
                                  title: missed > 0 ? '${(missed/total*100).toStringAsFixed(0)}%' : '',
                                  color: const Color(0xffef4444),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegendItem('Diminum ($taken)', const Color(0xff10b981)),
                            _buildLegendItem('Dilewati ($skipped)', const Color(0xfff59e0b)),
                            _buildLegendItem('Terlewat ($missed)', const Color(0xffef4444)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Weekly Bar chart progress
              Text(
                'Kepatuhan 7 Hari Terakhir',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (val, meta) {
                                return Text(
                                  '${val.toInt()}%',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final index = val.toInt();
                                if (index >= 0 && index < weekdayLabels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      weekdayLabels[index],
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(weeklyCompliance.length, (idx) {
                          final value = weeklyCompliance[idx];
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: value,
                                color: _getAdherenceColor(value),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 100,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return const Color(0xff10b981);
    if (rate >= 75) return const Color(0xfff59e0b);
    return const Color(0xffef4444);
  }
}
