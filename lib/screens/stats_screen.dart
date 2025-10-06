import 'package:flutter/material.dart';

import '../services/reminder_storage.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats =
        await ReminderStorage.getUserStats(); // ✅ ab bina arg ke chalega
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        backgroundColor: Colors.blue.shade600,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  _buildStatCard(
                    title: "Total Reminders",
                    value: _stats['total']?.toString() ?? '0',
                    icon: Icons.list_alt,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Active",
                          value: _stats['active']?.toString() ?? '0',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: "Completed",
                          value: _stats['completed']?.toString() ?? '0',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Today",
                          value: _stats['today']?.toString() ?? '0',
                          icon: Icons.today,
                          color: Colors.purple,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: "High Priority",
                          value: _stats['high']?.toString() ?? '0',
                          icon: Icons.priority_high,
                          color: Colors.red,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights, color: Colors.blue.shade600),
                              const SizedBox(width: 12),
                              const Text(
                                "Insights",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInsightRow(
                            "Completion Rate",
                            _calculateCompletionRate(),
                            Icons.trending_up,
                          ),
                          const Divider(height: 24),
                          _buildInsightRow(
                            "Active Tasks",
                            "${_stats['active']} pending",
                            Icons.hourglass_empty,
                          ),
                          const Divider(height: 24),
                          _buildInsightRow(
                            "Today's Focus",
                            "${_stats['today']} reminder${(_stats['today'] ?? 0) != 1 ? 's' : ''}",
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _calculateCompletionRate() {
    final total = _stats['total'] ?? 0;
    final completed = _stats['completed'] ?? 0;
    if (total == 0) return "0%";
    final rate = ((completed / total) * 100).toStringAsFixed(1);
    return "$rate%";
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: compact ? 32 : 40),
            SizedBox(height: compact ? 8 : 16),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 28 : 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
