import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/database_helper.dart';
import '../helpers/firebase_helper.dart';
import '../../constants/app_theme.dart';
import 'report_list_screen.dart';
import 'add_report_screen.dart';
import 'station_list_screen.dart';
import 'ai_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'total': 0, 'high': 0, 'unsynced': 0};
  bool _isOnline = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkConnectivity();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getStatsSummary();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOnline = result != ConnectivityResult.none);
  }

  Future<void> _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลัง sync ข้อมูล...'),
        duration: Duration(seconds: 1),
      ),
    );
    await FirebaseHelper.instance.syncPendingReports();
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync เสร็จแล้ว ✓'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _goto(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'รายงานทุจริตเลือกตั้ง',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A3A5C), Color(0xFF0D2238)],
                  ),
                ),
                child: Container(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    if ((_stats['unsynced'] ?? 0) > 0)
                      IconButton(
                        onPressed: _isOnline ? _syncNow : null,
                        icon: const Icon(
                          Icons.sync,
                          color: Colors.white,
                        ),
                        tooltip: 'Sync ${_stats['unsynced']} รายงาน',
                      ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isOnline ? AppColors.success : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOnline ? Icons.cloud_done : Icons.cloud_off,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isOnline ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            _StatCard(
                              label: 'ทั้งหมด',
                              value: _stats['total'].toString(),
                              icon: Icons.assignment,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'รุนแรงสูง',
                              value: _stats['high'].toString(),
                              icon: Icons.warning_rounded,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'รอ Sync',
                              value: _stats['unsynced'].toString(),
                              icon: Icons.sync,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),
                  const Text(
                    'เมนูหลัก',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _MenuCard(
                        icon: Icons.list_alt_rounded,
                        label: 'รายการรายงาน',
                        subtitle: 'ดูและจัดการรายงาน',
                        color: AppColors.primary,
                        onTap: () => _goto(const ReportListScreen()),
                      ),
                      _MenuCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'แจ้งเหตุใหม่',
                        subtitle: 'บันทึกเหตุทุจริต',
                        color: AppColors.accent,
                        onTap: () => _goto(const AddReportScreen()),
                      ),
                      _MenuCard(
                        icon: Icons.location_on_outlined,
                        label: 'หน่วยเลือกตั้ง',
                        subtitle: 'รายชื่อสถานที่',
                        color: const Color(0xFF5856D6),
                        onTap: () => _goto(const StationListScreen()),
                      ),
                      _MenuCard(
                        icon: Icons.document_scanner_outlined,
                        label: 'สแกน AI',
                        subtitle: 'วิเคราะห์ภาพหลักฐาน',
                        color: const Color(0xFF34C759),
                        onTap: () => _goto(const AiScanScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReportScreen()),
          );
          _loadStats();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'แจ้งเหตุ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
