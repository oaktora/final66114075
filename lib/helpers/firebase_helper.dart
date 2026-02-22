import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_report.dart';
import 'database_helper.dart';

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._init();
  FirebaseHelper._init();

  final _db = FirebaseFirestore.instance;

  Future<void> syncPendingReports() async {
    try {
      final pending = await DatabaseHelper.instance.getUnsyncedReports();
      for (final report in pending) {
        await pushReport(report);
        await DatabaseHelper.instance.markSynced(report.reportId!);
      }
    } catch (e) {
      debugPrint('sync failed: $e');
    }
  }

  Future<void> pushReport(IncidentReport report) async {
    final docRef = _db
        .collection('incident_reports')
        .doc(report.reportId.toString());

    String? photoUrl = report.evidencePhoto;
    if (photoUrl != null && !photoUrl.startsWith('http')) {
      photoUrl = 'OFFLINE_ONLY';
    }

    await docRef.set({
      'report_id': report.reportId,
      'station_id': report.stationId,
      'type_id': report.typeId,
      'reporter_name': report.reporterName,
      'description': report.description,
      'evidence_photo': photoUrl,
      'timestamp': report.timestamp,
      'ai_result': report.aiResult,
      'ai_confidence': report.aiConfidence,
    });
  }

  Future<void> deleteReport(int reportId) async {
    await _db.collection('incident_reports').doc(reportId.toString()).delete();
  }
}
