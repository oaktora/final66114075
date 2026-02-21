import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../../models/incident_report.dart';
import '../../models/polling_station.dart';
import '../../models/violation_type.dart';
import '../../constants/app_theme.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  List<IncidentReport> _reports = [];
  List<PollingStation> _stations = [];
  List<ViolationType> _types = [];
  bool _loading = true;
  String _filterSeverity = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final reports = await DatabaseHelper.instance.getAllReports();
    final stations = await DatabaseHelper.instance.getAllStations();
    final types = await DatabaseHelper.instance.getAllViolationTypes();
    if (mounted) {
      setState(() {
        _reports = reports;
        _stations = stations;
        _types = types;
        _loading = false;
      });
    }
  }

  List<IncidentReport> get _filtered {
    if (_filterSeverity == 'ทั้งหมด') return _reports;
    return _reports.where((r) {
      final t = _types.where((t) => t.typeId == r.typeId).firstOrNull;
      return t?.severity == _filterSeverity;
    }).toList();
  }

  String _stationName(int id) =>
      _stations.where((s) => s.stationId == id).firstOrNull?.stationName ??
      'ไม่ทราบ';

  ViolationType? _typeOf(int id) =>
      _types.where((t) => t.typeId == id).firstOrNull;

  String _formatDate(String ts) {
    try {
      final dt = DateTime.parse(ts.replaceFirst(' ', 'T'));
      return DateFormat('dd/MM\nHH:mm').format(dt);
    } catch (_) {
      return ts.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรายงาน'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['ทั้งหมด', 'High', 'Medium', 'Low'].map((s) {
                final selected = _filterSeverity == s;
                return GestureDetector(
                  onTap: () => setState(() => _filterSeverity = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s == 'ทั้งหมด' ? 'ทั้งหมด' : severityLabel(s),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected ? AppColors.primary : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีรายงาน',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final report = _filtered[i];
                  final type = _typeOf(report.typeId);
                  final sev = type?.severity ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: severityColor(sev).withOpacity(0.3),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(
                            report: report,
                            type: type,
                            stationName: _stationName(report.stationId),
                          ),
                        ),
                      ).then((_) => _loadData()),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: severityColor(sev),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          type?.typeName ?? 'ไม่ทราบประเภท',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (report.synced == 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'รอ Sync',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _stationName(report.stationId),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          report.reporterName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (report.aiResult != null) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.psychology, size: 14, color: Color(0xFF34C759)),
                                        const SizedBox(width: 4),
                                        Text(
                                          report.aiResult!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF34C759),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor(sev).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    severityLabel(sev),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: severityColor(sev),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(report.timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
