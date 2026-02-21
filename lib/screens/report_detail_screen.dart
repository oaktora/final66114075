import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../../models/incident_report.dart';
import '../../models/violation_type.dart';
import '../../constants/app_theme.dart';

class ReportDetailScreen extends StatelessWidget {
  final IncidentReport report;
  final ViolationType? type;
  final String stationName;

  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.type,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    final sev = type?.severity ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรายงาน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    severityColor(sev).withOpacity(0.15),
                    severityColor(sev).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: severityColor(sev).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor(sev),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severityLabel(sev),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    type?.typeName ?? 'ไม่ทราบ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.location_on,
              label: 'สถานที่',
              value: stationName,
            ),
            _InfoRow(
              icon: Icons.person,
              label: 'ผู้แจ้ง',
              value: report.reporterName,
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: 'วันเวลา',
              value: report.timestamp,
            ),
            if (report.description != null && report.description!.isNotEmpty)
              _InfoRow(
                icon: Icons.description,
                label: 'รายละเอียด',
                value: report.description!,
              ),
            if (report.synced == 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.sync, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ยังไม่ได้ sync ขึ้น Firebase (บันทึกใน SQLite แล้ว)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (report.aiResult != null || report.aiConfidence > 0) ...[
              const SizedBox(height: 20),
              const Text(
                'ผลการวิเคราะห์ AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF34C759).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: Color(0xFF34C759),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.aiResult ?? '-',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF34C759),
                          ),
                        ),
                        Text(
                          'Confidence: ${(report.aiConfidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: report.aiConfidence,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF34C759),
                        strokeWidth: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (report.evidencePhoto != null) ...[
              const SizedBox(height: 20),
              const Text(
                'หลักฐานภาพ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(report.evidencePhoto!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายงาน'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายงานนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteReport(report.reportId!);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('ลบ', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
